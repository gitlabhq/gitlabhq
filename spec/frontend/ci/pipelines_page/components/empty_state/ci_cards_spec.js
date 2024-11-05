import { GlButton, GlCard } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';

import CiCards from '~/ci/pipelines_page/components/empty_state/ci_cards.vue';

describe('CI Cards', () => {
  let wrapper;
  let trackingSpy;
  let firstCardData;

  const createComponent = ({ showJenkinsCiPrompt = true } = {}) => {
    wrapper = shallowMountExtended(CiCards, {
      provide: {
        pipelineEditorPath: '/-/ci/editor',
        showJenkinsCiPrompt,
      },
      stubs: {
        GlEmoji: { template: '<div/>' },
      },
    });
  };

  const findAllCards = () => wrapper.findAllComponents(GlCard);
  const findCardButton = () => wrapper.findComponent(GlButton);

  const findDescription = () => wrapper.findByTestId('ci-card-description');
  const findEmoji = () => wrapper.findByTestId('ci-card-emoji');
  const findTitle = () => wrapper.findByTestId('ci-card-title');

  describe('structure', () => {
    beforeEach(() => {
      createComponent();
      [firstCardData] = wrapper.vm.cards;
    });

    it('renders emoji', () => {
      expect(findEmoji().exists()).toBe(true);
      expect(findEmoji().attributes('data-name')).toBe(firstCardData.emoji);
    });

    it('renders title', () => {
      expect(findTitle().exists()).toBe(true);
      expect(findTitle().text()).toBe(firstCardData.title);
    });

    it('renders description', () => {
      expect(findDescription().exists()).toBe(true);
      expect(findDescription().text()).toBe(firstCardData.description);
    });

    it('renders button', () => {
      expect(findCardButton().exists()).toBe(true);
      expect(findCardButton().text()).toBe(firstCardData.buttonText);
    });
  });

  describe('visibility', () => {
    it('renders all cards if `showJenkinsCiPrompt` is true', () => {
      createComponent();
      expect(findAllCards()).toHaveLength(wrapper.vm.cards.length);
    });

    it('hides jenkins prompt if `showJenkinsCiPrompt` is false', () => {
      createComponent({ showJenkinsCiPrompt: false });
      expect(findAllCards()).toHaveLength(wrapper.vm.cards.length - 1);
    });
  });

  describe('tracking', () => {
    beforeEach(() => {
      createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('sends an event when template is clicked', () => {
      findCardButton().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledTimes(1);
    });
  });
});
