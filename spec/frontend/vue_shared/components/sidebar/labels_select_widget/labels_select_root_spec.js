import { shallowMount, createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import { IssuableType } from '~/issue_show/constants';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import DropdownContents from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_contents.vue';
import DropdownValue from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_value.vue';
import issueLabelsQuery from '~/vue_shared/components/sidebar/labels_select_widget/graphql/issue_labels.query.graphql';
import LabelsSelectRoot from '~/vue_shared/components/sidebar/labels_select_widget/labels_select_root.vue';
import { mockConfig, issuableLabelsQueryResponse } from './mock_data';

jest.mock('~/flash');

const localVue = createLocalVue();
localVue.use(VueApollo);

const successfulQueryHandler = jest.fn().mockResolvedValue(issuableLabelsQueryResponse);
const errorQueryHandler = jest.fn().mockRejectedValue('Houston, we have a problem');

describe('LabelsSelectRoot', () => {
  let wrapper;

  const findSidebarEditableItem = () => wrapper.findComponent(SidebarEditableItem);
  const findDropdownValue = () => wrapper.findComponent(DropdownValue);
  const findDropdownContents = () => wrapper.findComponent(DropdownContents);

  const createComponent = ({
    config = mockConfig,
    slots = {},
    queryHandler = successfulQueryHandler,
  } = {}) => {
    const mockApollo = createMockApollo([[issueLabelsQuery, queryHandler]]);

    wrapper = shallowMount(LabelsSelectRoot, {
      slots,
      apolloProvider: mockApollo,
      localVue,
      propsData: {
        ...config,
        issuableType: IssuableType.Issue,
        labelCreateType: 'project',
        workspaceType: 'project',
      },
      stubs: {
        SidebarEditableItem,
      },
      provide: {
        canUpdate: true,
        allowLabelEdit: true,
        allowLabelCreate: true,
        labelsManagePath: 'test',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders component with classes `labels-select-wrapper position-relative`', () => {
    createComponent();
    expect(wrapper.classes()).toEqual(['labels-select-wrapper', 'position-relative']);
  });

  it.each`
    variant         | cssClass
    ${'standalone'} | ${'is-standalone'}
    ${'embedded'}   | ${'is-embedded'}
  `(
    'renders component root element with CSS class `$cssClass` when `state.variant` is "$variant"',
    async ({ variant, cssClass }) => {
      createComponent({
        config: { ...mockConfig, variant },
      });

      await nextTick();
      expect(wrapper.classes()).toContain(cssClass);
    },
  );

  describe('if dropdown variant is `sidebar`', () => {
    it('renders sidebar editable item', () => {
      createComponent();
      expect(findSidebarEditableItem().exists()).toBe(true);
    });

    it('passes true `loading` prop to sidebar editable item when loading labels', () => {
      createComponent();
      expect(findSidebarEditableItem().props('loading')).toBe(true);
    });

    describe('when labels are fetched successfully', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('passes true `loading` prop to sidebar editable item', () => {
        expect(findSidebarEditableItem().props('loading')).toBe(false);
      });

      it('renders dropdown value component when query labels is resolved', () => {
        expect(findDropdownValue().exists()).toBe(true);
        expect(findDropdownValue().props('selectedLabels')).toEqual(
          issuableLabelsQueryResponse.data.workspace.issuable.labels.nodes,
        );
      });

      it('emits `onLabelRemove` event on dropdown value label remove event', () => {
        const label = { id: 'gid://gitlab/ProjectLabel/1' };
        findDropdownValue().vm.$emit('onLabelRemove', label);
        expect(wrapper.emitted('onLabelRemove')).toEqual([[label]]);
      });
    });

    it('creates flash with error message when query is rejected', async () => {
      createComponent({ queryHandler: errorQueryHandler });
      await waitForPromises();
      expect(createFlash).toHaveBeenCalledWith({ message: 'Error fetching labels.' });
    });
  });

  it('emits `updateSelectedLabels` event on dropdown contents `setLabels` event if iid is not set', async () => {
    const label = { id: 'gid://gitlab/ProjectLabel/1' };
    createComponent({ config: { ...mockConfig, iid: undefined } });

    findDropdownContents().vm.$emit('setLabels', [label]);
    expect(wrapper.emitted('updateSelectedLabels')).toEqual([[{ labels: [label] }]]);
  });
});
