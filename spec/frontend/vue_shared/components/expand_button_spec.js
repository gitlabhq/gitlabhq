import Vue from 'vue';
import { mount, createLocalVue } from '@vue/test-utils';
import ExpandButton from '~/vue_shared/components/expand_button.vue';

const text = {
  expanded: 'Expanded!',
  short: 'Short',
};

describe('Expand button', () => {
  let wrapper;

  const expanderPrependEl = () => wrapper.find('.js-text-expander-prepend');
  const expanderAppendEl = () => wrapper.find('.js-text-expander-append');

  const factory = (options = {}) => {
    const localVue = createLocalVue();

    wrapper = mount(localVue.extend(ExpandButton), {
      localVue,
      ...options,
    });
  };

  beforeEach(() => {
    factory({
      slots: {
        expanded: `<p>${text.expanded}</p>`,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the prepended collapse button', () => {
    expect(expanderPrependEl().isVisible()).toBe(true);
    expect(expanderAppendEl().isVisible()).toBe(false);
  });

  it('renders no text when short text is not provided', () => {
    expect(wrapper.find(ExpandButton).text()).toBe('');
  });

  it('does not render expanded text', () => {
    expect(
      wrapper
        .find(ExpandButton)
        .text()
        .trim(),
    ).not.toBe(text.short);
  });

  describe('when short text is provided', () => {
    beforeEach(() => {
      factory({
        slots: {
          expanded: `<p>${text.expanded}</p>`,
          short: `<p>${text.short}</p>`,
        },
      });
    });

    it('renders short text', () => {
      expect(
        wrapper
          .find(ExpandButton)
          .text()
          .trim(),
      ).toBe(text.short);
    });

    it('renders button before text', () => {
      expect(expanderPrependEl().isVisible()).toBe(true);
      expect(expanderAppendEl().isVisible()).toBe(false);
      expect(wrapper.find(ExpandButton).html()).toMatchSnapshot();
    });
  });

  describe('on click', () => {
    beforeEach(done => {
      expanderPrependEl().trigger('click');
      Vue.nextTick(done);
    });

    afterEach(() => {
      expanderAppendEl().trigger('click');
    });

    it('renders only the append collapse button', () => {
      expect(expanderAppendEl().isVisible()).toBe(true);
      expect(expanderPrependEl().isVisible()).toBe(false);
    });

    it('renders the expanded text', () => {
      expect(wrapper.find(ExpandButton).text()).toContain(text.expanded);
    });

    describe('when short text is provided', () => {
      beforeEach(done => {
        factory({
          slots: {
            expanded: `<p>${text.expanded}</p>`,
            short: `<p>${text.short}</p>`,
          },
        });

        expanderPrependEl().trigger('click');
        Vue.nextTick(done);
      });

      it('only renders expanded text', () => {
        expect(
          wrapper
            .find(ExpandButton)
            .text()
            .trim(),
        ).toBe(text.expanded);
      });

      it('renders button after text', () => {
        expect(expanderPrependEl().isVisible()).toBe(false);
        expect(expanderAppendEl().isVisible()).toBe(true);
        expect(wrapper.find(ExpandButton).html()).toMatchSnapshot();
      });
    });
  });

  describe('append button', () => {
    beforeEach(done => {
      expanderPrependEl().trigger('click');
      Vue.nextTick(done);
    });

    it('clicking hides itself and shows prepend', () => {
      expect(expanderAppendEl().isVisible()).toBe(true);
      expanderAppendEl().trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(expanderPrependEl().isVisible()).toBe(true);
      });
    });

    it('clicking hides expanded text', () => {
      expect(
        wrapper
          .find(ExpandButton)
          .text()
          .trim(),
      ).toBe(text.expanded);
      expanderAppendEl().trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(
          wrapper
            .find(ExpandButton)
            .text()
            .trim(),
        ).not.toBe(text.expanded);
      });
    });

    describe('when short text is provided', () => {
      beforeEach(done => {
        factory({
          slots: {
            expanded: `<p>${text.expanded}</p>`,
            short: `<p>${text.short}</p>`,
          },
        });

        expanderPrependEl().trigger('click');
        Vue.nextTick(done);
      });

      it('clicking reveals short text', () => {
        expect(
          wrapper
            .find(ExpandButton)
            .text()
            .trim(),
        ).toBe(text.expanded);
        expanderAppendEl().trigger('click');

        return wrapper.vm.$nextTick().then(() => {
          expect(
            wrapper
              .find(ExpandButton)
              .text()
              .trim(),
          ).toBe(text.short);
        });
      });
    });
  });
});
