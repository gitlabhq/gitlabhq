import Vue, { nextTick } from 'vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import { DUMMY_IMAGE_URL, TEST_HOST } from 'spec/test_constants';
import Badge from '~/badges/components/badge.vue';

describe('Badge component', () => {
  const Component = Vue.extend(Badge);
  const dummyProps = {
    imageUrl: DUMMY_IMAGE_URL,
    linkUrl: `${TEST_HOST}/badge/link/url`,
  };
  let vm;

  const findElements = () => {
    const buttons = vm.$el.querySelectorAll('button');
    return {
      badgeImage: vm.$el.querySelector('img.project-badge'),
      loadingIcon: vm.$el.querySelector('.gl-spinner'),
      reloadButton: buttons[buttons.length - 1],
    };
  };

  const createComponent = (props, el = null) => {
    vm = mountComponent(Component, props, el);
    const { badgeImage } = findElements();
    return new Promise((resolve) => {
      badgeImage.addEventListener('load', resolve);
      // Manually dispatch load event as it is not triggered
      badgeImage.dispatchEvent(new Event('load'));
    }).then(() => nextTick());
  };

  afterEach(() => {
    vm.$destroy();
  });

  describe('watchers', () => {
    describe('imageUrl', () => {
      it('sets isLoading and resets numRetries and hasError', async () => {
        const props = { ...dummyProps };
        await createComponent(props);
        expect(vm.isLoading).toBe(false);
        vm.hasError = true;
        vm.numRetries = 42;

        vm.imageUrl = `${props.imageUrl}#something/else`;
        await nextTick();
        expect(vm.isLoading).toBe(true);
        expect(vm.numRetries).toBe(0);
        expect(vm.hasError).toBe(false);
      });
    });
  });

  describe('methods', () => {
    beforeEach(async () => {
      await createComponent({ ...dummyProps });
    });

    it('onError resets isLoading and sets hasError', () => {
      vm.hasError = false;
      vm.isLoading = true;

      vm.onError();

      expect(vm.hasError).toBe(true);
      expect(vm.isLoading).toBe(false);
    });

    it('onLoad sets isLoading', () => {
      vm.isLoading = true;

      vm.onLoad();

      expect(vm.isLoading).toBe(false);
    });

    it('reloadImage resets isLoading and hasError and increases numRetries', () => {
      vm.hasError = true;
      vm.isLoading = false;
      vm.numRetries = 0;

      vm.reloadImage();

      expect(vm.hasError).toBe(false);
      expect(vm.isLoading).toBe(true);
      expect(vm.numRetries).toBe(1);
    });
  });

  describe('behavior', () => {
    beforeEach((done) => {
      setFixtures('<div id="dummy-element"></div>');
      createComponent({ ...dummyProps }, '#dummy-element')
        .then(done)
        .catch(done.fail);
    });

    it('shows a badge image after loading', () => {
      expect(vm.isLoading).toBe(false);
      expect(vm.hasError).toBe(false);
      const { badgeImage, loadingIcon, reloadButton } = findElements();

      expect(badgeImage).toBeVisible();
      expect(loadingIcon).toBeHidden();
      expect(reloadButton).toBeHidden();
      expect(vm.$el.querySelector('.btn-group')).toBeHidden();
    });

    it('shows a loading icon when loading', async () => {
      vm.isLoading = true;

      await nextTick();
      const { badgeImage, loadingIcon, reloadButton } = findElements();

      expect(badgeImage).toBeHidden();
      expect(loadingIcon).toBeVisible();
      expect(reloadButton).toBeHidden();
      expect(vm.$el.querySelector('.btn-group')).toBeHidden();
    });

    it('shows an error and reload button if loading failed', async () => {
      vm.hasError = true;

      await nextTick();
      const { badgeImage, loadingIcon, reloadButton } = findElements();

      expect(badgeImage).toBeHidden();
      expect(loadingIcon).toBeHidden();
      expect(reloadButton).toBeVisible();
      expect(reloadButton).toHaveSpriteIcon('retry');
      expect(vm.$el.innerText.trim()).toBe('No badge image');
    });
  });
});
