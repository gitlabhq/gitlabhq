import { mount } from '@vue/test-utils';
import { GlDrawer } from '@gitlab/ui';
import { getDrawerBodyHeight } from '~/whats_new/utils/get_drawer_body_height';

describe('~/whats_new/utils/get_drawer_body_height', () => {
  let drawerWrapper;

  beforeEach(() => {
    drawerWrapper = mount(GlDrawer, {
      propsData: { open: true },
    });
  });

  afterEach(() => {
    drawerWrapper.destroy();
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
