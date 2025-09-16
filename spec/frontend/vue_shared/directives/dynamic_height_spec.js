import { shallowMount } from '@vue/test-utils';
import DynamicHeight from '~/vue_shared/directives/dynamic_height';

// Mock the utility class
jest.mock('~/vue_shared/utils/dynamic_height', () => ({
  DynamicHeightManager: jest.fn().mockImplementation((element, options) => ({
    element,
    options,
    init: jest.fn(),
    updateOptions: jest.fn(),
    destroy: jest.fn(),
  })),
}));

describe('v-dynamic-height directive', () => {
  let wrapper;
  let mockElement;

  const createComponent = (directiveValue = undefined) => {
    const component = {
      directives: {
        DynamicHeight,
      },
      data() {
        return {
          directiveOptions: directiveValue,
        };
      },
      template: `
        <div v-dynamic-height="directiveOptions" data-testid="test-element">
          Test content
        </div>
      `,
    };

    wrapper = shallowMount(component, { attachTo: document.body });
    mockElement = wrapper.find('[data-testid="test-element"]').element;
  };

  describe('inserted hook', () => {
    it('initializes DynamicHeightManager with default options when no value provided', () => {
      createComponent();

      expect(mockElement.GL_DYNAMIC_HEIGHT).toBeDefined();
      expect(mockElement.GL_DYNAMIC_HEIGHT.init).toHaveBeenCalled();
      expect(mockElement.GL_DYNAMIC_HEIGHT.options).toEqual({});
    });

    it('initializes DynamicHeightManager with custom options when object value provided', () => {
      const customOptions = {
        closest: '.custom-wrapper',
        minHeight: 300,
        debounce: 100,
      };

      createComponent(customOptions);

      expect(mockElement.GL_DYNAMIC_HEIGHT).toBeDefined();
      expect(mockElement.GL_DYNAMIC_HEIGHT.init).toHaveBeenCalled();
      expect(mockElement.GL_DYNAMIC_HEIGHT.options).toEqual(customOptions);
    });

    it('does not reinitialize if manager already exists', () => {
      createComponent();

      const originalManager = mockElement.GL_DYNAMIC_HEIGHT;

      // Simulate calling inserted again
      DynamicHeight.inserted(mockElement, { value: {} });

      expect(mockElement.GL_DYNAMIC_HEIGHT).toBe(originalManager);
    });
  });

  describe('componentUpdated hook', () => {
    it('updates options when directive value changes', () => {
      const initialOptions = { minHeight: 300 };
      createComponent(initialOptions);

      const manager = mockElement.GL_DYNAMIC_HEIGHT;
      const newOptions = { minHeight: 400, closest: '.new-wrapper' };

      // Manually trigger componentUpdated since Vue Test Utils doesn't automatically call directive hooks
      DynamicHeight.componentUpdated(mockElement, { value: newOptions });

      expect(manager.updateOptions).toHaveBeenCalledWith(newOptions);
    });

    it('handles case when manager does not exist', () => {
      createComponent();

      // Remove the manager
      delete mockElement.GL_DYNAMIC_HEIGHT;

      expect(() => {
        DynamicHeight.componentUpdated(mockElement, { value: {} });
      }).not.toThrow();
    });
  });

  describe('unbind hook', () => {
    it('destroys the manager and cleans up references', () => {
      createComponent();

      const manager = mockElement.GL_DYNAMIC_HEIGHT;
      expect(manager).toBeDefined();

      DynamicHeight.unbind(mockElement);

      expect(manager.destroy).toHaveBeenCalled();
      expect(mockElement.GL_DYNAMIC_HEIGHT).toBeNull();
    });

    it('handles case when manager does not exist', () => {
      createComponent();

      // Remove the manager
      delete mockElement.GL_DYNAMIC_HEIGHT;

      expect(() => {
        DynamicHeight.unbind(mockElement);
      }).not.toThrow();
    });
  });

  describe('integration with Vue lifecycle', () => {
    it('properly initializes and cleans up during component lifecycle', () => {
      createComponent({
        closest: '.content-wrapper',
        minHeight: 500,
      });

      const manager = mockElement.GL_DYNAMIC_HEIGHT;
      expect(manager.init).toHaveBeenCalled();

      wrapper.destroy();

      expect(manager.destroy).toHaveBeenCalled();
    });

    it('handles multiple directive updates', () => {
      createComponent({ minHeight: 300 });

      const manager = mockElement.GL_DYNAMIC_HEIGHT;

      // First update
      DynamicHeight.componentUpdated(mockElement, { value: { minHeight: 400 } });

      // Second update
      DynamicHeight.componentUpdated(mockElement, {
        value: { minHeight: 500, closest: '.new-wrapper' },
      });

      expect(manager.updateOptions).toHaveBeenCalledTimes(2);
      expect(manager.updateOptions).toHaveBeenLastCalledWith({
        minHeight: 500,
        closest: '.new-wrapper',
      });
    });
  });
});
