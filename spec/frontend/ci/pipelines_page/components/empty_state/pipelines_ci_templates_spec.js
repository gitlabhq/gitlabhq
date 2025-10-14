import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelinesCiTemplates from '~/ci/pipelines_page/components/empty_state/pipelines_ci_templates.vue';
import CiCards from '~/ci/pipelines_page/components/empty_state/ci_cards.vue';
import CiTemplates from '~/ci/pipelines_page/components/empty_state/ci_templates.vue';
import ExternalConfigEmptyState from '~/ci/common/empty_state/external_config_empty_state.vue';

describe('Pipelines CI Templates', () => {
  let wrapper;

  const createWrapper = (provide = {}) => {
    wrapper = shallowMountExtended(PipelinesCiTemplates, {
      provide: {
        usesExternalConfig: false,
        emptyStateIllustrationPath: 'illustrations/empty-state/empty-pipeline-md.svg',
        ...provide,
      },
    });
  };

  const findCiCards = () => wrapper.findComponent(CiCards);
  const findCiTemplates = () => wrapper.findComponent(CiTemplates);
  const findPageTitle = () => wrapper.findByText('Get started with GitLab CI/CD');
  const findExternalConfigEmptyState = () => wrapper.findComponent(ExternalConfigEmptyState);

  describe('on mount', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders title', () => {
      expect(findPageTitle().exists()).toBe(true);
    });

    it('does not render ExternalConfigEmptyState component by default', () => {
      expect(findExternalConfigEmptyState().exists()).toBe(false);
    });
  });

  describe('cards', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders CiCards component', () => {
      expect(findCiCards().exists()).toBe(true);
    });
  });

  describe('templates', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders CiTemplates component', () => {
      expect(findCiTemplates().exists()).toBe(true);
    });
  });

  describe('when usesExternalConfig is true', () => {
    beforeEach(() => {
      createWrapper({ usesExternalConfig: true });
    });

    it('renders ExternalConfigEmptyState component', () => {
      expect(findExternalConfigEmptyState().exists()).toBe(true);
    });

    it('does not render ci card & templates', () => {
      expect(findPageTitle().exists()).toBe(false);
      expect(findCiCards().exists()).toBe(false);
      expect(findCiTemplates().exists()).toBe(false);
    });
  });
});
