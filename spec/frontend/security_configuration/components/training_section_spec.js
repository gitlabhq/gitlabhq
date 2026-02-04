import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TrainingSection from '~/security_configuration/components/training_section.vue';
import FeatureCard from '~/security_configuration/components/feature_card.vue';
import TrainingProviderList from '~/security_configuration/components/training_provider_list.vue';

describe('TrainingSection component', () => {
  let wrapper;

  const vulnerabilityTrainingDocsPath = '/help/vulnerability-training';

  const createComponent = ({ isFeatureAvailableOnCurrentTier = false } = {}) => {
    wrapper = shallowMountExtended(TrainingSection, {
      provide: {
        vulnerabilityTrainingDocsPath,
      },
      propsData: {
        isFeatureAvailableOnCurrentTier,
      },
    });
  };

  const findFeatureCard = () => wrapper.findComponent(FeatureCard);
  const findSectionLayout = () => wrapper.findByTestId('security-training-section');
  const findTrainingProviderList = () => wrapper.findComponent(TrainingProviderList);
  const findLink = () => wrapper.findComponent(GlLink);

  describe('when security training is disabled (free tier)', () => {
    beforeEach(() => {
      createComponent({ isFeatureAvailableOnCurrentTier: false });
    });

    it('renders FeatureCard', () => {
      expect(findFeatureCard().exists()).toBe(true);
    });

    it('does not render the security training section layout', () => {
      expect(findSectionLayout().exists()).toBe(false);
    });

    it('passes correct feature props to FeatureCard', () => {
      const feature = findFeatureCard().props('feature');

      expect(feature).toMatchObject({
        name: 'Security training',
        description: expect.stringMatching(
          'Enable security training to help your developers learn how to fix vulnerabilities.',
        ),
        helpPath: vulnerabilityTrainingDocsPath,
        type: 'security_training',
        available: false,
        configured: false,
      });
    });
  });

  describe('when security training is enabled (ultimate tier)', () => {
    beforeEach(() => {
      createComponent({ isFeatureAvailableOnCurrentTier: true });
    });

    it('renders the security training section layout', () => {
      expect(findSectionLayout().exists()).toBe(true);
    });

    it('does not render FeatureCard', () => {
      expect(findFeatureCard().exists()).toBe(false);
    });

    it('passes correct props to SectionLayout', () => {
      expect(findSectionLayout().props()).toMatchObject({
        stacked: true,
        heading: 'Security training',
      });
    });

    it('renders the training provider list', () => {
      expect(findTrainingProviderList().exists()).toBe(true);
    });

    it('renders the description text', () => {
      expect(wrapper.text()).toContain('Enable security training to help your developers');
    });

    it('renders the learn-more link with the correct href', () => {
      expect(findLink().attributes('href')).toBe(vulnerabilityTrainingDocsPath);
      expect(findLink().text()).toBe('Learn more about vulnerability training');
    });
  });
});
