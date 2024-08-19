import { GlAlert } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import AssociationsList from '~/admin/users/components/associations/associations_list.vue';

describe('AssociationsList', () => {
  let wrapper;

  const defaultPropsData = {
    associationsCount: {
      groups_count: 1,
      projects_count: 1,
      issues_count: 1,
      merge_requests_count: 1,
    },
  };

  const findAlert = () => wrapper.findComponent(GlAlert);

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(AssociationsList, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  describe('when there is an error', () => {
    it('displays an alert', () => {
      createComponent({
        propsData: {
          associationsCount: new Error(),
        },
      });

      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toContain(
        "An error occurred while fetching this user's contributions",
      );
    });
  });

  describe('with no errors', () => {
    it('does not display an alert', () => {
      createComponent();

      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('when counts are singular', () => {
    it('renders singular counts', () => {
      createComponent();

      expect(wrapper.text()).toContain(`${defaultPropsData.associationsCount.groups_count} group`);
      expect(wrapper.text()).toContain(`${defaultPropsData.associationsCount.issues_count} issue`);
      expect(wrapper.text()).toContain(
        `${defaultPropsData.associationsCount.projects_count} project`,
      );
      expect(wrapper.text()).toContain(
        `${defaultPropsData.associationsCount.merge_requests_count} merge request`,
      );
    });
  });

  describe('when counts are plural', () => {
    it('renders plural counts', () => {
      const propsData = {
        associationsCount: {
          groups_count: 2,
          projects_count: 3,
          issues_count: 4,
          merge_requests_count: 5,
        },
      };

      createComponent({ propsData });

      expect(wrapper.text()).toContain(`${propsData.associationsCount.groups_count} groups`);
      expect(wrapper.text()).toContain(`${propsData.associationsCount.issues_count} issues`);
      expect(wrapper.text()).toContain(`${propsData.associationsCount.projects_count} projects`);
      expect(wrapper.text()).toContain(
        `${propsData.associationsCount.merge_requests_count} merge requests`,
      );
    });
  });

  describe('when counts are 0', () => {
    it('does not render items', () => {
      createComponent({
        propsData: {
          associationsCount: {
            groups_count: 0,
            projects_count: 0,
            issues_count: 0,
            merge_requests_count: 0,
          },
        },
      });

      expect(wrapper.find('*').exists()).toBe(false);
    });
  });
});
