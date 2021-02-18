import { GlButton } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import DagAnnotations from '~/pipelines/components/dag/dag_annotations.vue';
import { singleNote, multiNote } from './mock_data';

describe('The DAG annotations', () => {
  let wrapper;

  const getColorBlock = () => wrapper.find('[data-testid="dag-color-block"]');
  const getAllColorBlocks = () => wrapper.findAll('[data-testid="dag-color-block"]');
  const getTextBlock = () => wrapper.find('[data-testid="dag-note-text"]');
  const getAllTextBlocks = () => wrapper.findAll('[data-testid="dag-note-text"]');
  const getToggleButton = () => wrapper.find(GlButton);

  const createComponent = (propsData = {}, method = shallowMount) => {
    if (wrapper?.destroy) {
      wrapper.destroy();
    }

    wrapper = method(DagAnnotations, {
      propsData,
      data() {
        return {
          showList: true,
        };
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

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
      it('hides listed items and changes text to show', () => {
        expect(getAllTextBlocks().length).toBe(Object.keys(multiNote).length);
        expect(getToggleButton().text()).toBe('Hide list');
        getToggleButton().trigger('click');
        return wrapper.vm.$nextTick().then(() => {
          expect(getAllTextBlocks().length).toBe(0);
          expect(getToggleButton().text()).toBe('Show list');
        });
      });
    });

    describe('clicking show', () => {
      it('shows listed items and changes text to hide', () => {
        getToggleButton().trigger('click');
        getToggleButton().trigger('click');

        return wrapper.vm.$nextTick().then(() => {
          expect(getAllTextBlocks().length).toBe(Object.keys(multiNote).length);
          expect(getToggleButton().text()).toBe('Hide list');
        });
      });
    });
  });
});
