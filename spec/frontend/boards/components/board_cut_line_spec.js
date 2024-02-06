import { shallowMount } from '@vue/test-utils';
import BoardCutLine from '~/boards/components/board_cut_line.vue';

describe('BoardCutLine', () => {
  let wrapper;
  const cutLineText = 'Work in progress limit: 3';

  const createComponent = (props) => {
    wrapper = shallowMount(BoardCutLine, { propsData: props });
  };

  describe('when cut line is shown', () => {
    beforeEach(() => {
      createComponent({ cutLineText });
    });

    it('contains cut line text in the template', () => {
      expect(wrapper.find('[data-testid="cut-line-text"]').text()).toContain(
        `Work in progress limit: 3`,
      );
    });

    it('does not contain other text in the template', () => {
      expect(wrapper.find('[data-testid="cut-line-text"]').text()).not.toContain(`unexpected`);
    });
  });
});
