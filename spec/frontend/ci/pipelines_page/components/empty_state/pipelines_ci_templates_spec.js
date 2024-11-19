import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelinesCiTemplates from '~/ci/pipelines_page/components/empty_state/pipelines_ci_templates.vue';
import CiCards from '~/ci/pipelines_page/components/empty_state/ci_cards.vue';
import CiTemplates from '~/ci/pipelines_page/components/empty_state/ci_templates.vue';

describe('Pipelines CI Templates', () => {
  let wrapper;

  const createWrapper = () => {
    return shallowMountExtended(PipelinesCiTemplates, {});
  };

  const findCiCards = () => wrapper.findComponent(CiCards);
  const findCiTemplates = () => wrapper.findComponent(CiTemplates);
  const findPageTitle = () => wrapper.findByText('Get started with GitLab CI/CD');

  describe('on mount', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('renders title', () => {
      expect(findPageTitle().exists()).toBe(true);
    });
  });

  describe('cards', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('renders CiCards component', () => {
      expect(findCiCards().exists()).toBe(true);
    });
  });

  describe('templates', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('renders CiTemplates component', () => {
      expect(findCiTemplates().exists()).toBe(true);
    });
  });
});
