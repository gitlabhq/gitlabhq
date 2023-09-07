import { GlButton } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DagAnnotations from '~/ci/pipeline_details/dag/components/dag_annotations.vue';
import { singleNote, multiNote } from '../mock_data';

describe('The DAG annotations', () => {
  let wrapper;

  const getColorBlock = () => wrapper.find('[data-testid="dag-color-block"]');
  const getAllColorBlocks = () => wrapper.findAll('[data-testid="dag-color-block"]');
  const getTextBlock = () => wrapper.find('[data-testid="dag-note-text"]');
  const getAllTextBlocks = () => wrapper.findAll('[data-testid="dag-note-text"]');
  const getToggleButton = () => wrapper.findComponent(GlButton);

  const createComponent = (propsData = {}, method = shallowMount) => {
    wrapper = method(DagAnnotations, {
      propsData,
      data() {
        return {
          showList: true,
        };
      },
    });
  };

  describe('when there is one annotation', () => {
    const currentNote = singleNote['dag-link103'];

    beforeEach(() => {
      createComponent({ annotations: singleNote });
    });

    it('displays the color block', () => {
      expect(getColorBlock().exists()).toBe(true);
    });

    it('displays the text block', () => {
      expect(getTextBlock().exists()).toBe(true);
      expect(getTextBlock().text()).toBe(`${currentNote.source.name} → ${currentNote.target.name}`);
    });

    it('does not display the list toggle link', () => {
      expect(getToggleButton().exists()).toBe(false);
    });
  });

  describe('when there are multiple annoataions', () => {
    beforeEach(() => {
      createComponent({ annotations: multiNote });
    });

    it('displays a color block for each link', () => {
      expect(getAllColorBlocks().length).toBe(Object.keys(multiNote).length);
    });

    it('displays a text block for each link', () => {
      expect(getAllTextBlocks().length).toBe(Object.keys(multiNote).length);

      Object.values(multiNote).forEach((item, idx) => {
        expect(getAllTextBlocks().at(idx).text()).toBe(`${item.source.name} → ${item.target.name}`);
      });
    });

    it('displays the list toggle link', () => {
      expect(getToggleButton().exists()).toBe(true);
      expect(getToggleButton().text()).toBe('Hide list');
    });
  });

  describe('the list toggle', () => {
    beforeEach(() => {
      createComponent({ annotations: multiNote }, mount);
    });

    describe('clicking hide', () => {
      it('hides listed items and changes text to show', async () => {
        expect(getAllTextBlocks().length).toBe(Object.keys(multiNote).length);
        expect(getToggleButton().text()).toBe('Hide list');
        getToggleButton().trigger('click');
        await nextTick();
        expect(getAllTextBlocks().length).toBe(0);
        expect(getToggleButton().text()).toBe('Show list');
      });
    });

    describe('clicking show', () => {
      it('shows listed items and changes text to hide', async () => {
        getToggleButton().trigger('click');
        getToggleButton().trigger('click');

        await nextTick();
        expect(getAllTextBlocks().length).toBe(Object.keys(multiNote).length);
        expect(getToggleButton().text()).toBe('Hide list');
      });
    });
  });
});
