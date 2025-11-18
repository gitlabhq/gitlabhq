import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelinesCiTemplates from '~/ci/pipelines_page/components/empty_state/pipelines_ci_templates.vue';
import CiCards from '~/ci/pipelines_page/components/empty_state/ci_cards.vue';
import CiTemplates from '~/ci/pipelines_page/components/empty_state/ci_templates.vue';

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

  describe('on mount', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders title', () => {
      expect(findPageTitle().exists()).toBe(true);
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
});
