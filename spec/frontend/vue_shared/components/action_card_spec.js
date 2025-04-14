import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ActionCard from '~/vue_shared/components/action_card.vue';

describe('Action card', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(ActionCard, {
      propsData: {
        title: 'Create a project',
        description:
          'Projects are where you store your code, access issues, wiki, and other features of GitLab.',
        icon: 'project',
        ...propsData,
      },
    });
  };

  const findTitle = () => wrapper.findByTestId('action-card-title');
  const findTitleLink = () => wrapper.findComponent(GlLink);
  const findDescription = () => wrapper.findByTestId('action-card-description');
  const findCardIcon = () => wrapper.findByTestId('action-card-icon');
  const findArrowIcon = () => wrapper.findByTestId('action-card-arrow-icon');

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders title', () => {
      expect(findTitle().text()).toBe('Create a project');
    });

    it('renders description', () => {
      expect(findDescription().text()).toBe(
        'Projects are where you store your code, access issues, wiki, and other features of GitLab.',
      );
    });

    it('renders card icon', () => {
      expect(findCardIcon().props('name')).toBe('project');
    });

    it('does not render link', () => {
      expect(findTitleLink().exists()).toBe(false);
    });
  });

  describe('with link', () => {
    beforeEach(() => {
      createComponent({ propsData: { href: 'gitlab.com' } });
    });

    it('renders link', () => {
      expect(findTitleLink().exists()).toBe(true);
      expect(findTitleLink().text()).toBe('Create a project');
      expect(findTitleLink().attributes('href')).toBe('gitlab.com');
    });

    it('renders card icon', () => {
      expect(findCardIcon().props('name')).toBe('project');
    });

    it('renders arrow icon', () => {
      expect(findArrowIcon().exists()).toBe(true);
    });
  });
});
