import { mount, shallowMount } from '@vue/test-utils';
import StageNavItem from '~/cycle_analytics/components/stage_nav_item.vue';

describe('StageNavItem', () => {
  let wrapper = null;
  const title = 'Cool stage';
  const value = '1 day';

  function createComponent(props, shallow = true) {
    const func = shallow ? shallowMount : mount;
    return func(StageNavItem, {
      propsData: {
        canEdit: false,
        isActive: false,
        isUserAllowed: false,
        isDefaultStage: true,
        title,
        value,
        ...props,
      },
    });
  }

  function hasStageName() {
    const stageName = wrapper.find('.stage-name');
    expect(stageName.exists()).toBe(true);
    expect(stageName.text()).toEqual(title);
  }

  it('renders stage name', () => {
    wrapper = createComponent({ isUserAllowed: true });
    hasStageName();
    wrapper.destroy();
  });

  describe('User has access', () => {
    describe('with a value', () => {
      beforeEach(() => {
        wrapper = createComponent({ isUserAllowed: true });
      });

      afterEach(() => {
        wrapper.destroy();
      });
      it('renders the value for median value', () => {
        expect(wrapper.find('.stage-empty').exists()).toBe(false);
        expect(wrapper.find('.not-available').exists()).toBe(false);
        expect(wrapper.find('.stage-median').text()).toEqual(value);
      });
    });

    describe('without a value', () => {
      beforeEach(() => {
        wrapper = createComponent({ isUserAllowed: true, value: null });
      });

      afterEach(() => {
        wrapper.destroy();
      });

      it('has the stage-empty class', () => {
        expect(wrapper.find('.stage-empty').exists()).toBe(true);
      });

      it('renders Not enough data for the median value', () => {
        expect(wrapper.find('.stage-median').text()).toEqual('Not enough data');
      });
    });
  });

  describe('is active', () => {
    beforeEach(() => {
      wrapper = createComponent({ isActive: true }, false);
    });

    afterEach(() => {
      wrapper.destroy();
    });
    it('has the active class', () => {
      expect(wrapper.find('.stage-nav-item').classes('active')).toBe(true);
    });
  });

  describe('is not active', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
    });
    it('emits the `select` event when clicked', () => {
      expect(wrapper.emitted().select).toBeUndefined();
      wrapper.trigger('click');
      expect(wrapper.emitted().select.length).toBe(1);
    });
  });

  describe('User does not have access', () => {
    beforeEach(() => {
      wrapper = createComponent({ isUserAllowed: false }, false);
    });

    afterEach(() => {
      wrapper.destroy();
    });
    it('renders stage name', () => {
      hasStageName();
    });

    it('has class not-available', () => {
      expect(wrapper.find('.stage-empty').exists()).toBe(false);
      expect(wrapper.find('.not-available').exists()).toBe(true);
    });

    it('renders Not available for the median value', () => {
      expect(wrapper.find('.stage-median').text()).toBe('Not available');
    });
    it('does not render options menu', () => {
      expect(wrapper.find('.more-actions-toggle').exists()).toBe(false);
    });
  });

  describe('User can edit stages', () => {
    beforeEach(() => {
      wrapper = createComponent({ canEdit: true, isUserAllowed: true }, false);
    });

    afterEach(() => {
      wrapper.destroy();
    });
    it('renders stage name', () => {
      hasStageName();
    });

    it('does not render options menu', () => {
      expect(wrapper.find('.more-actions-toggle').exists()).toBe(false);
    });

    it('can not edit the stage', () => {
      expect(wrapper.text()).not.toContain('Edit stage');
    });
    it('can not remove the stage', () => {
      expect(wrapper.text()).not.toContain('Remove stage');
    });

    it('can not hide the stage', () => {
      expect(wrapper.text()).not.toContain('Hide stage');
    });
  });
});
