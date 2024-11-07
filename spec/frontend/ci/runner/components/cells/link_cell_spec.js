import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LinkCell from '~/ci/runner/components/cells/link_cell.vue';

describe('LinkCell', () => {
  let wrapper;
  let onClick;

  const findLink = () => wrapper.findComponent(GlLink);
  const findSpan = () => wrapper.find('span');

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(LinkCell, {
      propsData: {
        ...props,
      },
      attrs: { foo: 'bar' },
      slots: {
        default: 'My Text',
      },
      listeners: {
        click: onClick,
      },
    });
  };

  beforeEach(() => {
    onClick = jest.fn();
  });

  describe('works as a wrapper', () => {
    describe('when an href is provided', () => {
      beforeEach(() => {
        createComponent({ href: '/url' });
      });

      it('renders a link', () => {
        expect(findLink().exists()).toBe(true);
      });

      it('passes attributes', () => {
        expect(findLink().attributes()).toMatchObject({ foo: 'bar' });
      });

      it('passes event listeners', () => {
        expect(onClick).toHaveBeenCalledTimes(0);

        findLink().vm.$emit('click');

        expect(onClick).toHaveBeenCalledTimes(1);
      });
    });

    describe('when an href is not provided', () => {
      beforeEach(() => {
        createComponent({ href: null });
      });

      it('renders no link', () => {
        expect(findLink().exists()).toBe(false);
      });

      it('passes attributes', () => {
        expect(findSpan().attributes()).toMatchObject({ foo: 'bar' });
      });

      it('passes event listeners', () => {
        expect(onClick).toHaveBeenCalledTimes(0);

        findSpan().trigger('click');

        expect(onClick).toHaveBeenCalledTimes(1);
      });
    });
  });
});
