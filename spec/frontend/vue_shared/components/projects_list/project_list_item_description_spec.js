import { GlIcon, GlSprintf, GlTruncateText } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProjectListItemDescription from '~/vue_shared/components/projects_list/project_list_item_description.vue';
import ListItemDescription from '~/vue_shared/components/resource_lists/list_item_description.vue';

describe('ProjectListItemDescription', () => {
  let wrapper;

  const defaultProps = {
    project: { id: 1 },
  };

  const descriptionHtml = '<p>Foo bar</p>';

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(ProjectListItemDescription, {
      propsData: { ...defaultProps, ...props },
      stubs: { GlTruncateText, GlSprintf },
    });
  };

  const findListItemDescription = () => wrapper.findComponent(ListItemDescription);
  const findGlIcon = () => wrapper.findComponent(GlIcon);

  describe('when project has a description but is archived', () => {
    it('does not render description', () => {
      createComponent({
        props: {
          project: {
            ...defaultProps.project,
            archived: true,
            descriptionHtml,
          },
        },
      });

      expect(findListItemDescription().exists()).toBe(false);
    });
  });

  describe('when project has a description and is not archived', () => {
    it('renders description', () => {
      createComponent({
        props: {
          project: {
            ...defaultProps.project,
            descriptionHtml,
          },
        },
      });

      expect(findListItemDescription().props('descriptionHtml')).toBe(descriptionHtml);
    });
  });

  describe('when project does not have a description', () => {
    it('does not render description', () => {
      createComponent();

      expect(findListItemDescription().exists()).toBe(false);
    });
  });

  describe('when pending deletion', () => {
    it('renders correct icon and scheduled for deletion information', () => {
      createComponent({
        props: {
          project: {
            ...defaultProps.project,
            markedForDeletionOn: '2024-12-24',
            permanentDeletionDate: '2024-12-31',
          },
        },
      });

      expect(findGlIcon().props('name')).toBe('calendar');
      expect(wrapper.text().replace(/\s+/g, ' ')).toBe('Scheduled for deletion on Dec 31, 2024');
    });
  });
});
