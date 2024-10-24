import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import ExpandButton from '~/releases/components/expand_button.vue';

const text = {
  expanded: 'Expanded!',
  short: 'Short',
};

describe('Expand button', () => {
  let wrapper;

  const expanderPrependEl = () => wrapper.find('.js-text-expander-prepend');
  const expanderAppendEl = () => wrapper.find('.js-text-expander-append');

  const factory = (options = {}) => {
    wrapper = mount(ExpandButton, {
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

  it('renders the prepended collapse button', () => {
    expect(expanderPrependEl().isVisible()).toBe(true);
    expect(expanderAppendEl().isVisible()).toBe(false);
  });

  it('renders no text when short text is not provided', () => {
    expect(wrapper.findComponent(ExpandButton).text()).toBe('');
  });

  it('does not render expanded text', () => {
    expect(wrapper.findComponent(ExpandButton).text().trim()).not.toBe(text.short);
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
      expect(wrapper.findComponent(ExpandButton).text().trim()).toBe(text.short);
    });

    it('renders button before text', () => {
      expect(expanderPrependEl().isVisible()).toBe(true);
      expect(expanderAppendEl().isVisible()).toBe(false);
      expect(wrapper.findComponent(ExpandButton).element).toMatchSnapshot();
    });
  });

  describe('on click', () => {
    beforeEach(async () => {
      expanderPrependEl().trigger('click');
      await nextTick();
    });

    afterEach(() => {
      expanderAppendEl().trigger('click');
    });

    it('renders only the append collapse button', () => {
      expect(expanderAppendEl().isVisible()).toBe(true);
      expect(expanderPrependEl().isVisible()).toBe(false);
    });

    it('renders the expanded text', () => {
      expect(wrapper.findComponent(ExpandButton).text()).toContain(text.expanded);
    });

    describe('when short text is provided', () => {
      beforeEach(async () => {
        factory({
          slots: {
            expanded: `<p>${text.expanded}</p>`,
            short: `<p>${text.short}</p>`,
          },
        });

        expanderPrependEl().trigger('click');
        await nextTick();
      });

      it('only renders expanded text', () => {
        expect(wrapper.findComponent(ExpandButton).text().trim()).toBe(text.expanded);
      });

      it('renders button after text', () => {
        expect(expanderPrependEl().isVisible()).toBe(false);
        expect(expanderAppendEl().isVisible()).toBe(true);
        expect(wrapper.findComponent(ExpandButton).element).toMatchSnapshot();
      });
    });
  });

  describe('append button', () => {
    beforeEach(async () => {
      expanderPrependEl().trigger('click');
      await nextTick();
    });

    it('clicking hides itself and shows prepend', async () => {
      expect(expanderAppendEl().isVisible()).toBe(true);
      expanderAppendEl().trigger('click');

      await nextTick();
      expect(expanderPrependEl().isVisible()).toBe(true);
    });

    it('clicking hides expanded text', async () => {
      expect(wrapper.findComponent(ExpandButton).text().trim()).toBe(text.expanded);
      expanderAppendEl().trigger('click');

      await nextTick();
      expect(wrapper.findComponent(ExpandButton).text().trim()).not.toBe(text.expanded);
    });

    describe('when short text is provided', () => {
      beforeEach(async () => {
        factory({
          slots: {
            expanded: `<p>${text.expanded}</p>`,
            short: `<p>${text.short}</p>`,
          },
        });

        expanderPrependEl().trigger('click');
        await nextTick();
      });

      it('clicking reveals short text', async () => {
        expect(wrapper.findComponent(ExpandButton).text().trim()).toBe(text.expanded);
        expanderAppendEl().trigger('click');

        await nextTick();
        expect(wrapper.findComponent(ExpandButton).text().trim()).toBe(text.short);
      });
    });
  });
});
