import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RepositoryHealthPerformanceCard from '~/usage_quotas/storage/project/components/repository_health_details/repository_health_details_performance_card.vue';

const MOCK_FEATURES = [
  { label: 'Feature One', enabled: true },
  { label: 'Feature Two', enabled: false },
  { label: 'Feature Three', enabled: true },
];

describe('RepositoryHealthPerformanceCard', () => {
  let wrapper;

  const defaultProps = {
    headerText: 'Test Header',
    noFeaturesText: 'No features available',
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(RepositoryHealthPerformanceCard, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findHeaderText = () => wrapper.findByTestId('performance-card-header');
  const findFeatures = () => wrapper.findAllByTestId('performance-card-feature');
  const findFooterText = () => wrapper.findByTestId('performance-card-footer');
  const findNoFeaturesText = () => wrapper.findByTestId('performance-card-no-features');

  describe('card header', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders header text', () => {
      expect(findHeaderText().text()).toBe(defaultProps.headerText);
    });
  });

  describe('with features', () => {
    beforeEach(() => {
      createComponent({
        props: {
          features: MOCK_FEATURES,
          footerText: 'Footer text',
        },
      });
    });

    it.each`
      index | expectedIcon         | expectedClasses
      ${0}  | ${'check-circle'}    | ${['gl-mr-3', 'gl-text-success']}
      ${1}  | ${'canceled-circle'} | ${['gl-mr-3']}
      ${2}  | ${'check-circle'}    | ${['gl-mr-3', 'gl-text-success']}
    `('renders feature $index correctly', ({ index, expectedIcon, expectedClasses }) => {
      const feature = findFeatures().at(index);
      const icon = feature.findComponent(GlIcon);

      expect(icon.props('name')).toBe(expectedIcon);
      expect(icon.classes()).toStrictEqual(expect.arrayContaining(expectedClasses));
      expect(feature.text()).toBe(MOCK_FEATURES[index].label);
    });

    it('renders footer text', () => {
      expect(findFooterText().text()).toBe('Footer text');
    });

    it('does not render no feature text', () => {
      expect(findNoFeaturesText().exists()).toBe(false);
    });
  });

  describe('without features', () => {
    beforeEach(() => {
      createComponent({ props: { features: [] } });
    });

    it('renders no features text', () => {
      expect(findNoFeaturesText().text()).toBe(defaultProps.noFeaturesText);
    });

    it('does not render feature', () => {
      expect(findFeatures()).toHaveLength(0);
    });

    it('does not render footer text', () => {
      expect(findFooterText().exists()).toBe(false);
    });
  });
});
