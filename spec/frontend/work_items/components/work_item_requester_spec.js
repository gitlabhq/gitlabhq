import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemSidebarWidget from '~/work_items/components/shared/work_item_sidebar_widget.vue';
import WorkItemRequester from '~/work_items/components/work_item_requester.vue';
import workItemRequesterQuery from '~/work_items/graphql/work_item_requester.query.graphql';
import { workItemRequesterResponseFactory } from 'ee_else_ce_jest/work_items/mock_data';

Vue.use(VueApollo);

describe('WorkItemRequester component', () => {
  let wrapper;

  const successHandler = jest.fn().mockResolvedValue(workItemRequesterResponseFactory());

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findLink = () => wrapper.findComponent(GlLink);
  const findSidebarWidget = () => wrapper.findComponent(WorkItemSidebarWidget);

  const createComponent = ({ handler = successHandler } = {}) => {
    wrapper = shallowMount(WorkItemRequester, {
      apolloProvider: createMockApollo([[workItemRequesterQuery, handler]]),
      propsData: {
        fullPath: 'group/project',
        workItemIid: '1',
      },
    });
  };

  describe('when the work item has a requester', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders the title', () => {
      expect(wrapper.text()).toContain('Requester');
    });

    it('renders a mail icon', () => {
      expect(findIcon().props('name')).toBe('mail');
    });

    it('renders a mailto link with the requester email', () => {
      expect(findLink().attributes('href')).toBe('mailto:requester@example.com');
      expect(findLink().text()).toBe('requester@example.com');
    });
  });

  describe('when the work item has no requester', () => {
    beforeEach(async () => {
      createComponent({
        handler: jest.fn().mockResolvedValue(workItemRequesterResponseFactory({ email: null })),
      });
      await waitForPromises();
    });

    it('does not render the widget', () => {
      expect(findSidebarWidget().exists()).toBe(false);
    });
  });
});
