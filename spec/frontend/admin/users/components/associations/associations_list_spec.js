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

      expect(wrapper.html()).toMatchSnapshot();
    });
  });

  describe('when counts are singular', () => {
    it('renders singular counts', () => {
      createComponent();

      expect(wrapper.html()).toMatchSnapshot();
    });
  });

  describe('when counts are plural', () => {
    it('renders plural counts', () => {
      createComponent({
        propsData: {
          associationsCount: {
            groups_count: 2,
            projects_count: 3,
            issues_count: 4,
            merge_requests_count: 5,
          },
        },
      });

      expect(wrapper.html()).toMatchSnapshot();
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

      expect(wrapper.html()).toMatchSnapshot();
    });
  });
});
