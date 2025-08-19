import { GlIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FeaturedCarousel from '~/whats_new/components/featured_carousel.vue';
import FeaturedCard from '~/whats_new/components/featured_card.vue';
import { DOCS_URL } from 'jh_else_ce/lib/utils/url_utility';

describe('FeaturedCarousel', () => {
  let wrapper;

  const buildWrapper = () => {
    wrapper = shallowMountExtended(FeaturedCarousel);
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findTitle = () => wrapper.find('h5');
  const findPreviousButton = () => wrapper.findByTestId('card-carousel-previous-button');
  const findNextButton = () => wrapper.findByTestId('card-carousel-next-button');
  const findCounter = () => wrapper.findByTestId('card-counter');
  const findFeaturedCards = () => wrapper.findAllComponents(FeaturedCard);

  describe('rendering', () => {
    beforeEach(() => {
      buildWrapper();
    });

    it('renders the header with icon and title', () => {
      expect(findIcon().exists()).toBe(true);
      expect(findIcon().props('name')).toBe('compass');
      expect(findIcon().props('size')).toBe(16);
      expect(findTitle().text()).toBe('Featured updates');
    });

    it('renders navigation buttons', () => {
      const previousButton = findPreviousButton();
      const nextButton = findNextButton();
      const previousIcon = previousButton.findComponent(GlIcon);
      const nextIcon = nextButton.findComponent(GlIcon);

      expect(previousButton.exists()).toBe(true);
      expect(previousButton.props('category')).toBe('tertiary');
      expect(previousIcon.props('name')).toBe('chevron-lg-left');
      expect(nextButton.exists()).toBe(true);
      expect(nextButton.props('category')).toBe('tertiary');
      expect(nextIcon.props('name')).toBe('chevron-lg-right');
    });

    it('renders the counter with initial state', () => {
      expect(findCounter().text().trim()).toBe('1 / 2');
    });

    it('renders two featured cards', () => {
      const cards = findFeaturedCards();
      expect(cards).toHaveLength(2);
    });

    it('renders first featured card with correct props', () => {
      const firstCard = findFeaturedCards().at(0);

      expect(firstCard.props('title')).toBe('Granular access controls for GitLab Duo Core');
      expect(firstCard.props('description')).toBe(
        'Set detailed permissions for GitLab Duo Core across projects and groups to fit your workflow.',
      );
      expect(firstCard.props('buttonLink')).toBe(`${DOCS_URL}/user/gitlab_duo/turn_on_off`);
    });

    it('renders second featured card with correct props', () => {
      const secondCard = findFeaturedCards().at(1);

      expect(secondCard.props('title')).toBe('GitLab Premium and Ultimate with Duo');
      expect(secondCard.props('description')).toBe(
        'Discover AI-native features including Code Suggestions and Chat in your IDE in GitLab Premium and Ultimate.',
      );
      expect(secondCard.props('buttonLink')).toBe(
        `${DOCS_URL}/subscriptions/subscription-add-ons/#gitlab-duo-core`,
      );
    });
  });

  describe('navigation functionality', () => {
    beforeEach(() => {
      buildWrapper();
    });

    describe('nextCard method', () => {
      it('disables next button when at last card', async () => {
        expect(findNextButton().props('disabled')).toBe(false);

        wrapper.vm.nextCard();
        await nextTick();

        expect(findNextButton().props('disabled')).toBe(true);
      });

      it('updates counter display when moving to next card', async () => {
        wrapper.vm.nextCard();
        await nextTick();

        expect(findCounter().text()).toBe('2 / 2');
      });
    });

    describe('previousCard method', () => {
      it('disables previous button when at first card', () => {
        expect(findPreviousButton().props('disabled')).toBe(true);
      });

      it('updates counter display when moving to previous card', async () => {
        wrapper.vm.nextCard();
        await nextTick();

        wrapper.vm.previousCard();
        await nextTick();

        expect(findCounter().text()).toBe('1 / 2');
      });
    });
  });
});
