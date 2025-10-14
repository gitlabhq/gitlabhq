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

  const descriptionHtml = '<p>Foo bar</p>';
  const description = 'Plain text description';

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(ListItemDescription, {
      propsData: { ...defaultProps, ...props },
      stubs: { GlTruncateText, GlSprintf },
    });
  };

  const findDescription = () => wrapper.findByTestId('description');
  const findDescriptionHtml = () => wrapper.findByTestId('description-html');
  const findGlIcon = () => wrapper.findComponent(GlIcon);

  describe('when resource has a description but is archived', () => {
    it('does not render descriptionHtml', () => {
      createComponent({
        props: {
          resource: {
            ...project,
            archived: true,
            descriptionHtml,
          },
        },
      });

      expect(findDescriptionHtml().exists()).toBe(false);
    });

    it('does not render plain text description when archived', () => {
      createComponent({
        props: {
          resource: {
            ...project,
            archived: true,
            description,
          },
        },
      });

      expect(findDescription().exists()).toBe(false);
    });
  });

  describe('when resource has a plain text description and is not archived', () => {
    it('renders plain text description', () => {
      createComponent({
        props: {
          resource: {
            ...project,
            description,
          },
        },
      });

      expect(findDescription().exists()).toBe(true);
      expect(findDescription().text()).toBe(description);
      expect(findDescriptionHtml().exists()).toBe(false);
    });

    it('does not render as HTML', () => {
      createComponent({
        props: {
          resource: {
            ...project,
            description,
          },
        },
      });

      expect(findDescription().attributes('v-safe-html')).toBeUndefined();
      expect(findDescription().classes()).toContain('md');
    });
  });

  describe('when resource has descriptionHtml and is not archived', () => {
    it('renders description as HTML', () => {
      createComponent({
        props: {
          resource: {
            ...project,
            descriptionHtml,
          },
        },
      });

      expect(findDescriptionHtml().exists()).toBe(true);
      expect(findDescriptionHtml().text()).toBe('Foo bar');
      expect(findDescription().exists()).toBe(false);
    });
  });

  describe('when resource has both description and descriptionHtml', () => {
    it('prioritizes descriptionHtml over plain text description', () => {
      createComponent({
        props: {
          resource: {
            ...project,
            description,
            descriptionHtml,
          },
        },
      });

      expect(findDescriptionHtml().exists()).toBe(true);
      expect(findDescriptionHtml().text()).toBe('Foo bar');
      expect(findDescription().exists()).toBe(false);
    });
  });

  describe('when resource does not have a description', () => {
    it('does not render description', () => {
      createComponent();

      expect(findDescription().exists()).toBe(false);
      expect(findDescriptionHtml().exists()).toBe(false);
    });
  });

  describe('when project is pending deletion', () => {
    it('renders correct icon and scheduled for deletion information', () => {
      createComponent({
        props: {
          resource: {
            ...project,
            markedForDeletion: true,
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
