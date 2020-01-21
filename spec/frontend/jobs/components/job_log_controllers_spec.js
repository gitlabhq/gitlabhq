import Vue from 'vue';
import component from '~/jobs/components/job_log_controllers.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Job log controllers', () => {
  const Component = Vue.extend(component);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  const props = {
    rawPath: '/raw',
    erasePath: '/erase',
    size: 511952,
    isScrollTopDisabled: false,
    isScrollBottomDisabled: false,
    isScrollingDown: true,
    isTraceSizeVisible: true,
  };

  describe('Truncate information', () => {
    describe('with isTraceSizeVisible', () => {
      beforeEach(() => {
        vm = mountComponent(Component, props);
      });

      it('renders size information', () => {
        expect(vm.$el.querySelector('.js-truncated-info').textContent).toContain('499.95 KiB');
      });

      it('renders link to raw trace', () => {
        expect(vm.$el.querySelector('.js-raw-link').getAttribute('href')).toEqual('/raw');
      });
    });
  });

  describe('links section', () => {
    describe('with raw trace path', () => {
      it('renders raw trace link', () => {
        vm = mountComponent(Component, props);

        expect(vm.$el.querySelector('.js-raw-link-controller').getAttribute('href')).toEqual(
          '/raw',
        );
      });
    });

    describe('without raw trace path', () => {
      it('does not render raw trace link', () => {
        vm = mountComponent(Component, {
          erasePath: '/erase',
          size: 511952,
          isScrollTopDisabled: true,
          isScrollBottomDisabled: true,
          isScrollingDown: false,
          isTraceSizeVisible: true,
        });

        expect(vm.$el.querySelector('.js-raw-link-controller')).toBeNull();
      });
    });

    describe('when is erasable', () => {
      beforeEach(() => {
        vm = mountComponent(Component, props);
      });

      it('renders erase job link', () => {
        expect(vm.$el.querySelector('.js-erase-link')).not.toBeNull();
      });
    });

    describe('when it is not erasable', () => {
      it('does not render erase button', () => {
        vm = mountComponent(Component, {
          rawPath: '/raw',
          size: 511952,
          isScrollTopDisabled: true,
          isScrollBottomDisabled: true,
          isScrollingDown: false,
          isTraceSizeVisible: true,
        });

        expect(vm.$el.querySelector('.js-erase-link')).toBeNull();
      });
    });
  });

  describe('scroll buttons', () => {
    describe('scroll top button', () => {
      describe('when user can scroll top', () => {
        beforeEach(() => {
          vm = mountComponent(Component, props);
        });

        it('renders enabled scroll top button', () => {
          expect(vm.$el.querySelector('.js-scroll-top').getAttribute('disabled')).toBeNull();
        });

        it('emits scrollJobLogTop event on click', () => {
          jest.spyOn(vm, '$emit').mockImplementation(() => {});
          vm.$el.querySelector('.js-scroll-top').click();

          expect(vm.$emit).toHaveBeenCalledWith('scrollJobLogTop');
        });
      });

      describe('when user can not scroll top', () => {
        beforeEach(() => {
          vm = mountComponent(Component, {
            rawPath: '/raw',
            erasePath: '/erase',
            size: 511952,
            isScrollTopDisabled: true,
            isScrollBottomDisabled: false,
            isScrollingDown: false,
            isTraceSizeVisible: true,
          });
        });

        it('renders disabled scroll top button', () => {
          expect(vm.$el.querySelector('.js-scroll-top').getAttribute('disabled')).toEqual(
            'disabled',
          );
        });

        it('does not emit scrollJobLogTop event on click', () => {
          jest.spyOn(vm, '$emit').mockImplementation(() => {});
          vm.$el.querySelector('.js-scroll-top').click();

          expect(vm.$emit).not.toHaveBeenCalledWith('scrollJobLogTop');
        });
      });
    });

    describe('scroll bottom button', () => {
      describe('when user can scroll bottom', () => {
        beforeEach(() => {
          vm = mountComponent(Component, props);
        });

        it('renders enabled scroll bottom button', () => {
          expect(vm.$el.querySelector('.js-scroll-bottom').getAttribute('disabled')).toBeNull();
        });

        it('emits scrollJobLogBottom event on click', () => {
          jest.spyOn(vm, '$emit').mockImplementation(() => {});
          vm.$el.querySelector('.js-scroll-bottom').click();

          expect(vm.$emit).toHaveBeenCalledWith('scrollJobLogBottom');
        });
      });

      describe('when user can not scroll bottom', () => {
        beforeEach(() => {
          vm = mountComponent(Component, {
            rawPath: '/raw',
            erasePath: '/erase',
            size: 511952,
            isScrollTopDisabled: false,
            isScrollBottomDisabled: true,
            isScrollingDown: false,
            isTraceSizeVisible: true,
          });
        });

        it('renders disabled scroll bottom button', () => {
          expect(vm.$el.querySelector('.js-scroll-bottom').getAttribute('disabled')).toEqual(
            'disabled',
          );
        });

        it('does not emit scrollJobLogBottom event on click', () => {
          jest.spyOn(vm, '$emit').mockImplementation(() => {});
          vm.$el.querySelector('.js-scroll-bottom').click();

          expect(vm.$emit).not.toHaveBeenCalledWith('scrollJobLogBottom');
        });
      });

      describe('while isScrollingDown is true', () => {
        it('renders animate class for the scroll down button', () => {
          vm = mountComponent(Component, props);

          expect(vm.$el.querySelector('.js-scroll-bottom').className).toContain('animate');
        });
      });

      describe('while isScrollingDown is false', () => {
        it('does not render animate class for the scroll down button', () => {
          vm = mountComponent(Component, {
            rawPath: '/raw',
            erasePath: '/erase',
            size: 511952,
            isScrollTopDisabled: true,
            isScrollBottomDisabled: false,
            isScrollingDown: false,
            isTraceSizeVisible: true,
          });

          expect(vm.$el.querySelector('.js-scroll-bottom').className).not.toContain('animate');
        });
      });
    });
  });
});
