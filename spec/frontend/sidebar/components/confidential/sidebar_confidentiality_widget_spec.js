import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';

import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import SidebarConfidentialityContent from '~/sidebar/components/confidential/sidebar_confidentiality_content.vue';
import SidebarConfidentialityForm from '~/sidebar/components/confidential/sidebar_confidentiality_form.vue';
import SidebarConfidentialityWidget, {
  confidentialWidget,
} from '~/sidebar/components/confidential/sidebar_confidentiality_widget.vue';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import issueConfidentialQuery from '~/sidebar/queries/issue_confidential.query.graphql';
import { issueConfidentialityResponse } from '../../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('Sidebar Confidentiality Widget', () => {
  let wrapper;
  let fakeApollo;

  const findEditableItem = () => wrapper.findComponent(SidebarEditableItem);
  const findConfidentialityForm = () => wrapper.findComponent(SidebarConfidentialityForm);
  const findConfidentialityContent = () => wrapper.findComponent(SidebarConfidentialityContent);

  const createComponent = ({
    confidentialQueryHandler = jest.fn().mockResolvedValue(issueConfidentialityResponse()),
  } = {}) => {
    fakeApollo = createMockApollo([[issueConfidentialQuery, confidentialQueryHandler]]);

    wrapper = shallowMount(SidebarConfidentialityWidget, {
      apolloProvider: fakeApollo,
      provide: {
        canUpdate: true,
      },
      propsData: {
        fullPath: 'group/project',
        iid: '1',
        issuableType: 'issue',
      },
      stubs: {
        SidebarEditableItem,
      },
    });
  };

  afterEach(() => {
    fakeApollo = null;
  });

  it('passes a `loading` prop as true to editable item when query is loading', () => {
    createComponent();

    expect(findEditableItem().props('loading')).toBe(true);
  });

  it('exposes a method via external observable', () => {
    createComponent();

    expect(confidentialWidget.setConfidentiality).toEqual(wrapper.vm.setConfidentiality);
  });

  describe('when issue is not confidential', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('passes a `loading` prop as false to editable item', () => {
      expect(findEditableItem().props('loading')).toBe(false);
    });

    it('passes false to `confidential` prop of child components', () => {
      expect(findConfidentialityForm().props('confidential')).toBe(false);
      expect(findConfidentialityContent().props('confidential')).toBe(false);
    });

    it('changes confidentiality to true after setConfidentiality is called', async () => {
      confidentialWidget.setConfidentiality();
      await nextTick();
      expect(findConfidentialityForm().props('confidential')).toBe(true);
      expect(findConfidentialityContent().props('confidential')).toBe(true);
    });

    it('emits `confidentialityUpdated` event with a `false` payload', () => {
      expect(wrapper.emitted('confidentialityUpdated')).toEqual([[false]]);
    });
  });

  describe('when issue is confidential', () => {
    beforeEach(async () => {
      createComponent({
        confidentialQueryHandler: jest.fn().mockResolvedValue(issueConfidentialityResponse(true)),
      });
      await waitForPromises();
    });

    it('passes a `loading` prop as false to editable item', () => {
      expect(findEditableItem().props('loading')).toBe(false);
    });

    it('passes false to `confidential` prop of child components', () => {
      expect(findConfidentialityForm().props('confidential')).toBe(true);
      expect(findConfidentialityContent().props('confidential')).toBe(true);
    });

    it('changes confidentiality to false after setConfidentiality is called', async () => {
      confidentialWidget.setConfidentiality();
      await nextTick();
      expect(findConfidentialityForm().props('confidential')).toBe(false);
      expect(findConfidentialityContent().props('confidential')).toBe(false);
    });

    it('emits `confidentialityUpdated` event with a `true` payload', () => {
      expect(wrapper.emitted('confidentialityUpdated')).toEqual([[true]]);
    });
  });

  it('displays an alert message when query is rejected', async () => {
    createComponent({
      confidentialQueryHandler: jest.fn().mockRejectedValue('Houston, we have a problem'),
    });
    await waitForPromises();

    expect(createAlert).toHaveBeenCalled();
  });

  it('closes the form and dispatches an event when `closeForm` is emitted', async () => {
    createComponent();
    const el = wrapper.vm.$el;
    jest.spyOn(el, 'dispatchEvent');

    await waitForPromises();
    wrapper.vm.$refs.editable.expand();
    await nextTick();

    expect(findConfidentialityForm().isVisible()).toBe(true);

    findConfidentialityForm().vm.$emit('closeForm');
    await nextTick();
    expect(findConfidentialityForm().isVisible()).toBe(false);

    expect(el.dispatchEvent).toHaveBeenCalled();
    expect(wrapper.emitted('closeForm')).toEqual([[]]);
  });

  it('emits `expandSidebar` event when it is emitted from child component', async () => {
    createComponent();
    await waitForPromises();
    findConfidentialityContent().vm.$emit('expandSidebar');

    expect(wrapper.emitted('expandSidebar')).toHaveLength(1);
  });
});
