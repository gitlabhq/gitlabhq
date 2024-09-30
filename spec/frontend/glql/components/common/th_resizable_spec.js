import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ThResizable from '~/glql/components/common/th_resizable.vue';

describe('ThResizable', () => {
  let wrapper;
  let table;

  const findResizeHandle = () => wrapper.findByTestId('resize-handle');

  const createComponent = (props = {}) => {
    table = document.createElement('table');
    table.innerHTML = '<thead><tr><th></th></tr></thead>';

    document.body.appendChild(table);

    wrapper = mountExtended(ThResizable, {
      propsData: {
        table,
        ...props,
      },
      attachTo: table.querySelector('th'),
    });

    jest.spyOn(window, 'getComputedStyle').mockReturnValue({ width: '50px' });
  };

  afterEach(() => {
    table.remove();
  });

  it('renders the th element with a resize handle', () => {
    createComponent();

    expect(wrapper.find('th').exists()).toBe(true);
    expect(wrapper.findByTestId('resize-handle').exists()).toBe(true);
  });

  it('applies correct styles when resizing', async () => {
    createComponent();
    const th = wrapper.find('th');

    // Simulate start of resize
    await findResizeHandle().trigger('mousedown', { clientX: 100 });

    // Simulate mouse move
    document.dispatchEvent(new MouseEvent('mousemove', { clientX: 150 }));
    await nextTick();

    // initial width = 50, deltaX = 50, expected = 50 + 50 = 100
    expect(th.element.style.minWidth).toBe('100px');
    expect(th.element.style.maxWidth).toBe('100px');
  });

  it('applies correct styles when resizing ends', async () => {
    createComponent();
    const th = wrapper.find('th');

    // Start and end resize
    await findResizeHandle().trigger('mousedown', { clientX: 100 });
    document.dispatchEvent(new MouseEvent('mousemove', { clientX: 150 }));
    document.dispatchEvent(new MouseEvent('mouseup'));
    await nextTick();

    // initial width = 50, deltaX = 50, expected = 50 + 50 = 100
    expect(th.element.style.minWidth).toBe('100px');
    expect(th.element.style.maxWidth).toBe('100px');

    expect(wrapper.emitted('resize')).toHaveLength(1);
    expect(wrapper.emitted('resize')[0]).toEqual([100]);
  });

  it('updates resize handle height on mouseover', async () => {
    createComponent();

    // Set a fixed height for the table
    Object.defineProperty(table, 'clientHeight', { value: 200, writable: true });

    await findResizeHandle().trigger('mouseover');

    expect(findResizeHandle().element.style.height).toBe('200px');
  });
});
