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

  const baseCardClass = 'action-card';

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('applies default variant styles', () => {
      expect(wrapper.classes()).toContain(baseCardClass, 'action-card-default');
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

  describe.each`
    variant      | expectedVariantClass     | expectedCardIcon
    ${'success'} | ${'action-card-success'} | ${'check'}
    ${'promo'}   | ${'action-card-promo'}   | ${'project'}
  `('when variant is $variant', ({ variant, expectedVariantClass, expectedCardIcon }) => {
    beforeEach(() => {
      createComponent({ propsData: { variant } });
    });

    it('applies correct variant styles', () => {
      expect(wrapper.classes()).toContain(baseCardClass, expectedVariantClass);
    });

    it('renders correct card icon', () => {
      expect(findCardIcon().props('name')).toBe(expectedCardIcon);
    });
  });
});
