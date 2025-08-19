import { GlIcon, GlSprintf, GlTruncateText } from '@gitlab/ui';
import membershipProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/membership_projects.query.graphql.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ListItemDescription from '~/vue_shared/components/resource_lists/list_item_description.vue';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/formatter';
import { groups } from '../groups_list/mock_data';

describe('ListItemDescription', () => {
  let wrapper;

  const {
    data: {
      projects: { nodes: graphqlProjects },
    },
  } = membershipProjectsGraphQlResponse;

  const [project] = formatGraphQLProjects(graphqlProjects);
  const [group] = groups;

  const defaultProps = {
    resource: project,
  };

  const descriptionHtml = '<p data-testid="description">Foo bar</p>';

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(ListItemDescription, {
      propsData: { ...defaultProps, ...props },
      stubs: { GlTruncateText, GlSprintf },
    });
  };

  const findDescription = () => wrapper.findByTestId('description');
  const findGlIcon = () => wrapper.findComponent(GlIcon);

  describe('when resource has a description but is archived', () => {
    it('does not render description', () => {
      createComponent({
        props: {
          resource: {
            ...project,
            archived: true,
            descriptionHtml,
          },
        },
      });

      expect(findDescription().exists()).toBe(false);
    });
  });

  describe('when project has a description and is not archived', () => {
    it('renders description', () => {
      createComponent({
        props: {
          resource: {
            ...project,
            descriptionHtml,
          },
        },
      });

      expect(findDescription().text()).toBe('Foo bar');
    });
  });

  describe('when project does not have a description', () => {
    it('does not render description', () => {
      createComponent();

      expect(findDescription().exists()).toBe(false);
    });
  });

  describe('when project is pending deletion', () => {
    it('renders correct icon and scheduled for deletion information', () => {
      createComponent({
        props: {
          resource: {
            ...project,
            markedForDeletionOn: '2024-12-24',
            permanentDeletionDate: '2024-12-31',
          },
        },
      });

      expect(findGlIcon().props('name')).toBe('calendar');
      expect(wrapper.text()).toMatchInterpolatedText('Scheduled for deletion on Dec 31, 2024');
    });
  });

  describe('when group is pending deletion', () => {
    it('renders correct icon and scheduled for deletion information', () => {
      createComponent({
        props: {
          resource: {
            ...group,
            markedForDeletion: true,
            permanentDeletionDate: '2024-12-31',
          },
        },
      });

      expect(findGlIcon().props('name')).toBe('calendar');
      expect(wrapper.text()).toMatchInterpolatedText('Scheduled for deletion on Dec 31, 2024');
    });
  });
});
