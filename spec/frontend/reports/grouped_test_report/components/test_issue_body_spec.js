import { GlBadge, GlButton } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import IssueStatusIcon from '~/reports/components/issue_status_icon.vue';
import TestIssueBody from '~/reports/grouped_test_report/components/test_issue_body.vue';
import { failedIssue, successIssue } from '../../mock_data/mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Test issue body', () => {
  let wrapper;
  let store;

  const findDescription = () => wrapper.findByTestId('test-issue-body-description');
  const findStatusIcon = () => wrapper.findComponent(IssueStatusIcon);
  const findBadge = () => wrapper.findComponent(GlBadge);

  const actionSpies = {
    openModal: jest.fn(),
  };

  const createComponent = ({ issue = failedIssue } = {}) => {
    store = new Vuex.Store({
      actions: actionSpies,
    });

    wrapper = extendedWrapper(
      shallowMount(TestIssueBody, {
        store,
        localVue,
        propsData: {
          issue,
        },
        stubs: {
          GlBadge,
          GlButton,
          IssueStatusIcon,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when issue has failed status', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders issue name', () => {
      expect(findDescription().text()).toContain(failedIssue.name);
    });

    it('renders failed status icon', () => {
      expect(findStatusIcon().props('status')).toBe('failed');
    });

    describe('when issue has recent failures', () => {
      it('renders recent failures badge', () => {
        expect(findBadge().exists()).toBe(true);
      });
    });
  });

  describe('when issue has success status', () => {
    beforeEach(() => {
      createComponent({ issue: successIssue });
    });

    it('does not render recent failures', () => {
      expect(findBadge().exists()).toBe(false);
    });

    it('renders issue name', () => {
      expect(findDescription().text()).toBe(successIssue.name);
    });

    it('renders success status icon', () => {
      expect(findStatusIcon().props('status')).toBe('success');
    });
  });

  describe('when clicking on an issue', () => {
    it('calls openModal action', () => {
      createComponent();
      wrapper.findComponent(GlButton).trigger('click');

      expect(actionSpies.openModal).toHaveBeenCalledWith(expect.any(Object), {
        issue: failedIssue,
      });
    });
  });
});
