import $ from 'jquery';
import { mount } from '@vue/test-utils';
import tooltip from '~/vue_shared/directives/tooltip';

describe('Tooltip directive', () => {
  let vm;

  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });

  describe('with a single tooltip', () => {
    beforeEach(() => {
      const wrapper = mount(
        {
          directives: {
            tooltip,
          },
          data() {
            return {
              tooltip: 'some text',
            };
          },
          template: '<div v-tooltip :title="tooltip"></div>',
        },
        { attachToDocument: true },
      );

      vm = wrapper.vm;
    });

    it('should have tooltip plugin applied', () => {
      expect($(vm.$el).data('bs.tooltip')).toBeDefined();
    });

    it('displays the title as tooltip', () => {
      $(vm.$el).tooltip('show');
      jest.runOnlyPendingTimers();

      const tooltipElement = document.querySelector('.tooltip-inner');

      expect(tooltipElement.textContent).toContain('some text');
    });

    it('updates a visible tooltip', () => {
      $(vm.$el).tooltip('show');
      jest.runOnlyPendingTimers();

      const tooltipElement = document.querySelector('.tooltip-inner');

      vm.tooltip = 'other text';

      jest.runOnlyPendingTimers();

      return vm.$nextTick().then(() => {
        expect(tooltipElement.textContent).toContain('other text');
      });
    });
  });

  describe('with multiple tooltips', () => {
    beforeEach(() => {
      const wrapper = mount(
        {
          directives: {
            tooltip,
          },
          template: `
            <div>
              <div
                v-tooltip
                class="js-look-for-tooltip"
                title="foo">
              </div>
              <div
                v-tooltip
                title="bar">
              </div>
            </div>
          `,
        },
        { attachToDocument: true },
      );

      vm = wrapper.vm;
    });

    it('should have tooltip plugin applied to all instances', () => {
      expect(
        $(vm.$el)
          .find('.js-look-for-tooltip')
          .data('bs.tooltip'),
      ).toBeDefined();
    });
  });
});
