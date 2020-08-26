import { shallowMount } from '@vue/test-utils';
import { GlTooltip } from '@gitlab/ui';
import Tooltips from '~/tooltips/components/tooltips.vue';

describe('tooltips/components/tooltips.vue', () => {
  let wrapper;

  const buildWrapper = () => {
    wrapper = shallowMount(Tooltips);
  };

  const createTooltipTarget = (attributes = {}) => {
    const target = document.createElement('button');
    const defaults = {
      title: 'default title',
      ...attributes,
    };

    Object.keys(defaults).forEach(name => {
      target.setAttribute(name, defaults[name]);
    });

    return target;
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('addTooltips', () => {
    let target;

    beforeEach(() => {
      buildWrapper();

      target = createTooltipTarget();
    });

    it('attaches tooltips to the targets specified', async () => {
      wrapper.vm.addTooltips([target]);

      await wrapper.vm.$nextTick();

      expect(wrapper.find(GlTooltip).props('target')).toBe(target);
    });

    it('does not attach a tooltip twice to the same element', async () => {
      wrapper.vm.addTooltips([target]);
      wrapper.vm.addTooltips([target]);

      await wrapper.vm.$nextTick();

      expect(wrapper.findAll(GlTooltip)).toHaveLength(1);
    });

    it('sets tooltip content from title attribute', async () => {
      wrapper.vm.addTooltips([target]);

      await wrapper.vm.$nextTick();

      expect(wrapper.find(GlTooltip).text()).toBe(target.getAttribute('title'));
    });

    it('supports HTML content', async () => {
      target = createTooltipTarget({
        title: 'content with <b>HTML</b>',
        'data-html': true,
      });
      wrapper.vm.addTooltips([target]);

      await wrapper.vm.$nextTick();

      expect(wrapper.find(GlTooltip).html()).toContain(target.getAttribute('title'));
    });

    it.each`
      attribute           | value                 | prop
      ${'data-placement'} | ${'bottom'}           | ${'placement'}
      ${'data-container'} | ${'custom-container'} | ${'container'}
      ${'data-boundary'}  | ${'viewport'}         | ${'boundary'}
      ${'data-triggers'}  | ${'manual'}           | ${'triggers'}
    `(
      'sets $prop to $value when $attribute is set in target',
      async ({ attribute, value, prop }) => {
        target = createTooltipTarget({ [attribute]: value });
        wrapper.vm.addTooltips([target]);

        await wrapper.vm.$nextTick();

        expect(wrapper.find(GlTooltip).props(prop)).toBe(value);
      },
    );
  });
});
