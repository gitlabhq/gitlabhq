import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import FirstPipelineCard from '~/pipeline_editor/components/drawer/cards/first_pipeline_card.vue';
import GettingStartedCard from '~/pipeline_editor/components/drawer/cards/getting_started_card.vue';
import PipelineConfigReferenceCard from '~/pipeline_editor/components/drawer/cards/pipeline_config_reference_card.vue';
import VisualizeAndLintCard from '~/pipeline_editor/components/drawer/cards/visualize_and_lint_card.vue';
import PipelineEditorDrawer from '~/pipeline_editor/components/drawer/pipeline_editor_drawer.vue';

describe('Pipeline editor drawer', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(PipelineEditorDrawer);
  };

  const findFirstPipelineCard = () => wrapper.findComponent(FirstPipelineCard);
  const findGettingStartedCard = () => wrapper.findComponent(GettingStartedCard);
  const findPipelineConfigReferenceCard = () => wrapper.findComponent(PipelineConfigReferenceCard);
  const findToggleBtn = () => wrapper.findComponent(GlButton);
  const findVisualizeAndLintCard = () => wrapper.findComponent(VisualizeAndLintCard);

  const findArrowIcon = () => wrapper.find('[data-testid="toggle-icon"]');
  const findCollapseText = () => wrapper.find('[data-testid="collapse-text"]');
  const findDrawerContent = () => wrapper.find('[data-testid="drawer-content"]');

  const clickToggleBtn = async () => findToggleBtn().vm.$emit('click');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when the drawer is collapsed', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows the left facing arrow icon', () => {
      expect(findArrowIcon().props('name')).toBe('chevron-double-lg-left');
    });

    it('does not show the collapse text', () => {
      expect(findCollapseText().exists()).toBe(false);
    });

    it('does not show the drawer content', () => {
      expect(findDrawerContent().exists()).toBe(false);
    });

    it('can open the drawer by clicking on the toggle button', async () => {
      expect(findDrawerContent().exists()).toBe(false);

      await clickToggleBtn();

      expect(findDrawerContent().exists()).toBe(true);
    });
  });

  describe('when the drawer is expanded', () => {
    beforeEach(async () => {
      createComponent();
      await clickToggleBtn();
    });

    it('shows the right facing arrow icon', () => {
      expect(findArrowIcon().props('name')).toBe('chevron-double-lg-right');
    });

    it('shows the collapse text', () => {
      expect(findCollapseText().exists()).toBe(true);
    });

    it('shows the drawer content', () => {
      expect(findDrawerContent().exists()).toBe(true);
    });

    it('shows all the introduction cards', () => {
      expect(findFirstPipelineCard().exists()).toBe(true);
      expect(findGettingStartedCard().exists()).toBe(true);
      expect(findPipelineConfigReferenceCard().exists()).toBe(true);
      expect(findVisualizeAndLintCard().exists()).toBe(true);
    });

    it('can close the drawer by clicking on the toggle button', async () => {
      expect(findDrawerContent().exists()).toBe(true);

      await clickToggleBtn();

      expect(findDrawerContent().exists()).toBe(false);
    });
  });
});
