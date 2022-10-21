import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LinkCell from '~/ci/runner/components/cells/link_cell.vue';

describe('LinkCell', () => {
  let wrapper;

  const findGlLink = () => wrapper.findComponent(GlLink);
  const findSpan = () => wrapper.find('span');

  const createComponent = ({ props = {}, ...options } = {}) => {
    wrapper = shallowMountExtended(LinkCell, {
      propsData: {
        ...props,
      },
      ...options,
    });
  };

  it('when an href is provided, renders a link', () => {
    createComponent({ props: { href: '/url' } });
    expect(findGlLink().exists()).toBe(true);
  });

  it('when an href is not provided, renders no link', () => {
    createComponent();
    expect(findGlLink().exists()).toBe(false);
  });

  describe.each`
    href      | findContent
    ${null}   | ${findSpan}
    ${'/url'} | ${findGlLink}
  `('When href is $href', ({ href, findContent }) => {
    const content = 'My Text';
    const attrs = { foo: 'bar' };
    const listeners = {
      click: jest.fn(),
    };

    beforeEach(() => {
      createComponent({
        props: { href },
        slots: {
          default: content,
        },
        attrs,
        listeners,
      });
    });

    afterAll(() => {
      listeners.click.mockReset();
    });

    it('Renders content', () => {
      expect(findContent().text()).toBe(content);
    });

    it('Passes attributes', () => {
      expect(findContent().attributes()).toMatchObject(attrs);
    });

    it('Passes event listeners', () => {
      expect(listeners.click).toHaveBeenCalledTimes(0);

      findContent().vm.$emit('click');

      expect(listeners.click).toHaveBeenCalledTimes(1);
    });
  });
});
