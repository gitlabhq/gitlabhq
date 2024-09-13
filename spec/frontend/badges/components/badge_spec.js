import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';

import { DUMMY_IMAGE_URL, TEST_HOST } from 'spec/test_constants';
import Badge from '~/badges/components/badge.vue';

describe('Badge component', () => {
  const dummyProps = {
    imageUrl: DUMMY_IMAGE_URL,
    linkUrl: `${TEST_HOST}/badge/link/url`,
  };
  let wrapper;

  const findElements = () => {
    const buttons = wrapper.findAll('button');
    return {
      badgeImage: wrapper.find('img.project-badge'),
      loadingIcon: wrapper.find('.gl-spinner'),
      reloadButton: buttons.at(buttons.length - 1),
    };
  };

  const createComponent = (propsData) => {
    wrapper = mount(Badge, { propsData });
  };

  beforeEach(() => {
    return createComponent({ ...dummyProps }, '#dummy-element');
  });

  it('shows a badge image after loading', async () => {
    const { badgeImage, loadingIcon, reloadButton } = findElements();
    badgeImage.element.dispatchEvent(new Event('load'));

    await nextTick();

    expect(badgeImage.isVisible()).toBe(true);
    expect(loadingIcon.isVisible()).toBe(false);
    expect(reloadButton.isVisible()).toBe(false);
    expect(wrapper.find('.btn-group').isVisible()).toBe(false);
  });

  it('shows a loading icon when loading', () => {
    const { badgeImage, loadingIcon, reloadButton } = findElements();

    expect(badgeImage.isVisible()).toBe(false);
    expect(loadingIcon.isVisible()).toBe(true);
    expect(reloadButton.isVisible()).toBe(false);
    expect(wrapper.find('.btn-group').isVisible()).toBe(false);
  });

  it('shows an error and reload button if loading failed', async () => {
    const { badgeImage, loadingIcon, reloadButton } = findElements();
    badgeImage.element.dispatchEvent(new Event('error'));

    await nextTick();

    expect(badgeImage.isVisible()).toBe(false);
    expect(loadingIcon.isVisible()).toBe(false);
    expect(reloadButton.isVisible()).toBe(true);
    expect(reloadButton.element).toHaveSpriteIcon('retry');
    expect(wrapper.text()).toBe('No badge image');
  });

  it('retries an image when loading failed and reload button is clicked', async () => {
    const { badgeImage, reloadButton } = findElements();
    badgeImage.element.dispatchEvent(new Event('error'));
    await nextTick();

    await reloadButton.trigger('click');

    expect(badgeImage.element.src).toBe(`${dummyProps.imageUrl}#retries=1`);
  });
});
