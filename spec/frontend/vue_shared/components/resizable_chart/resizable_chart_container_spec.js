import { mount } from '@vue/test-utils';
import $ from 'jquery';
import Vue from 'vue';
import ResizableChartContainer from '~/vue_shared/components/resizable_chart/resizable_chart_container.vue';

jest.mock('~/lib/utils/common_utils', () => ({
  debounceByAnimationFrame(callback) {
    return jest.spyOn({ callback }, 'callback');
  },
}));

describe('Resizable Chart Container', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(ResizableChartContainer, {
      scopedSlots: {
        default: `
          <template #default="{ width, height }">
            <div class="slot">
              <span class="width">{{width}}</span>
              <span class="height">{{height}}</span>
            </div>
          </template>
        `,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the component', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('updates the slot width and height props', () => {
    const width = 1920;
    const height = 1080;

    // JSDOM mocks and sets clientWidth/clientHeight to 0 so we set manually
    wrapper.vm.$refs.chartWrapper = { clientWidth: width, clientHeight: height };

    $(document).trigger('content.resize');

    return Vue.nextTick().then(() => {
      const widthNode = wrapper.find('.slot > .width');
      const heightNode = wrapper.find('.slot > .height');

      expect(parseInt(widthNode.text(), 10)).toEqual(width);
      expect(parseInt(heightNode.text(), 10)).toEqual(height);
    });
  });

  it('calls onResize on manual resize', () => {
    $(document).trigger('content.resize');
    expect(wrapper.vm.debouncedResize).toHaveBeenCalled();
  });

  it('calls onResize on page resize', () => {
    window.dispatchEvent(new Event('resize'));
    expect(wrapper.vm.debouncedResize).toHaveBeenCalled();
  });
});
