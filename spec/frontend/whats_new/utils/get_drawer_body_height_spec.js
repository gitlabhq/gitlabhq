import { GlDrawer } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { getDrawerBodyHeight } from '~/whats_new/utils/get_drawer_body_height';

describe('~/whats_new/utils/get_drawer_body_height', () => {
  let drawerWrapper;

  beforeEach(() => {
    drawerWrapper = mount(GlDrawer, {
      propsData: { open: true },
    });
  });

  const setClientHeight = (el, height) => {
    Object.defineProperty(el, 'clientHeight', {
      get() {
        return height;
      },
    });
  };
  const setDrawerDimensions = ({ height, top, headerHeight }) => {
    const drawer = drawerWrapper.element;

    setClientHeight(drawer, height);
    jest.spyOn(drawer, 'getBoundingClientRect').mockReturnValue({ top });
    setClientHeight(drawer.querySelector('.gl-drawer-header'), headerHeight);
  };

  it('calculates height of drawer body', () => {
    setDrawerDimensions({ height: 100, top: 5, headerHeight: 40 });

    expect(getDrawerBodyHeight(drawerWrapper.element)).toBe(55);
  });
});
