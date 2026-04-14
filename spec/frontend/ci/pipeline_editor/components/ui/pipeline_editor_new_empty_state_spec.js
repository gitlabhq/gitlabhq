import { GlCard, GlEmptyState } from '@gitlab/ui';
import ROCKET_ILLUSTRATION from '@gitlab/svgs/dist/illustrations/rocket-launch-md.svg?url';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelineEditorEmptyState from '~/ci/pipeline_editor/components/ui/pipeline_editor_new_empty_state.vue';
import ExternalConfigEmptyState from '~/ci/common/empty_state/external_config_empty_state.vue';

describe('Pipeline editor new empty state', () => {
  let wrapper;

  const defaultProvide = {
    usesExternalConfig: false,
    newPipelinePath: '',
    ciCatalogPath: '/explore/catalog',
  };

  const createComponent = ({ provide } = {}) => {
    wrapper = shallowMountExtended(PipelineEditorEmptyState, {
      provide: { ...defaultProvide, ...provide },
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findExternalConfigEmptyState = () => wrapper.findComponent(ExternalConfigEmptyState);
  const findCards = () => wrapper.findAllComponents(GlCard);
  const findBrowseCatalogButton = () => wrapper.findByTestId('browse-catalog-button');
  const findCreateNewCiButton = () => wrapper.findByTestId('create-new-ci-button');

  describe('when project uses an external CI config', () => {
    const newPipelinePath = '/path-to-new-pipeline';

    beforeEach(() => {
      createComponent({
        provide: { usesExternalConfig: true, newPipelinePath },
      });
    });

    it('renders the external config empty state', () => {
      expect(findExternalConfigEmptyState().exists()).toBe(true);
    });

    it('provides newPipelinePath to the external config empty state', () => {
      expect(findExternalConfigEmptyState().props('newPipelinePath')).toBe(newPipelinePath);
    });
  });

  describe('when project uses an accessible CI config', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders an empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
      expect(findExternalConfigEmptyState().exists()).toBe(false);
    });

    it('renders correct title and illustration', () => {
      expect(findEmptyState().props('svgPath')).toBe(ROCKET_ILLUSTRATION);
      expect(findEmptyState().props('title')).toBe('Get up and running with GitLab CI/CD');
    });

    it('renders correct description text', () => {
      expect(findEmptyState().text()).toContain(
        'Streamline your development process effortlessly with robust CI/CD pipelines.',
      );
    });

    it('renders two cards', () => {
      expect(findCards()).toHaveLength(2);
    });

    describe('Browse catalog card', () => {
      it('renders the card with correct header', () => {
        const cards = findCards();
        expect(cards.at(0).text()).toContain('Use a CI/CD component');
      });

      it('renders the browse catalog button with correct href', () => {
        expect(findBrowseCatalogButton().exists()).toBe(true);
        expect(findBrowseCatalogButton().attributes('href')).toBe('/explore/catalog');
      });
    });

    describe('Start from scratch card', () => {
      it('renders the card with correct header', () => {
        const cards = findCards();
        expect(cards.at(1).text()).toContain('Write your own');
      });

      it('renders the start building button', () => {
        expect(findCreateNewCiButton().exists()).toBe(true);
      });

      it('emits create-empty-config-file event when clicking Start building button', async () => {
        const expectedEvent = 'create-empty-config-file';
        expect(wrapper.emitted(expectedEvent)).toBeUndefined();

        await findCreateNewCiButton().vm.$emit('click');
        expect(wrapper.emitted(expectedEvent)).toHaveLength(1);
      });
    });
  });
});
