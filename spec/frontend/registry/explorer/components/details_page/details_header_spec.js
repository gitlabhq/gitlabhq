import { GlSprintf, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { useFakeDate } from 'helpers/fake_date';
import component from '~/registry/explorer/components/details_page/details_header.vue';
import {
  DETAILS_PAGE_TITLE,
  UNSCHEDULED_STATUS,
  SCHEDULED_STATUS,
  ONGOING_STATUS,
  UNFINISHED_STATUS,
  CLEANUP_DISABLED_TEXT,
  CLEANUP_DISABLED_TOOLTIP,
  CLEANUP_SCHEDULED_TOOLTIP,
  CLEANUP_ONGOING_TOOLTIP,
  CLEANUP_UNFINISHED_TOOLTIP,
} from '~/registry/explorer/constants';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

describe('Details Header', () => {
  let wrapper;

  const defaultImage = {
    name: 'foo',
    updatedAt: '2020-11-03T13:29:21Z',
    tagsCount: 10,
    canDelete: true,
    project: {
      visibility: 'public',
      containerExpirationPolicy: {
        enabled: false,
      },
    },
  };

  // set the date to Dec 4, 2020
  useFakeDate(2020, 11, 4);
  const findByTestId = (testId) => wrapper.find(`[data-testid="${testId}"]`);

  const findLastUpdatedAndVisibility = () => findByTestId('updated-and-visibility');
  const findTitle = () => findByTestId('title');
  const findTagsCount = () => findByTestId('tags-count');
  const findCleanup = () => findByTestId('cleanup');
  const findDeleteButton = () => wrapper.find(GlButton);

  const waitForMetadataItems = async () => {
    // Metadata items are printed by a loop in the title-area and it takes two ticks for them to be available
    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();
  };

  const mountComponent = (propsData = { image: defaultImage }) => {
    wrapper = shallowMount(component, {
      propsData,
      stubs: {
        GlSprintf,
        TitleArea,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('has the correct title ', () => {
    mountComponent({ image: { ...defaultImage, name: '' } });
    expect(findTitle().text()).toMatchInterpolatedText(DETAILS_PAGE_TITLE);
  });

  it('shows imageName in the title', () => {
    mountComponent();
    expect(findTitle().text()).toContain('foo');
  });

  describe('delete button', () => {
    it('exists', () => {
      mountComponent();

      expect(findDeleteButton().exists()).toBe(true);
    });

    it('is hidden while loading', () => {
      mountComponent({ image: defaultImage, metadataLoading: true });

      expect(findDeleteButton().exists()).toBe(false);
    });

    it('has the correct text', () => {
      mountComponent();

      expect(findDeleteButton().text()).toBe('Delete');
    });

    it('has the correct props', () => {
      mountComponent();

      expect(findDeleteButton().props()).toMatchObject({
        variant: 'danger',
        disabled: false,
      });
    });

    it('emits the correct event', () => {
      mountComponent();

      findDeleteButton().vm.$emit('click');

      expect(wrapper.emitted('delete')).toEqual([[]]);
    });

    it.each`
      canDelete | disabled | isDisabled
      ${true}   | ${false} | ${false}
      ${true}   | ${true}  | ${true}
      ${false}  | ${false} | ${true}
      ${false}  | ${true}  | ${true}
    `(
      'when canDelete is $canDelete and disabled is $disabled is $isDisabled that the button is disabled',
      ({ canDelete, disabled, isDisabled }) => {
        mountComponent({ image: { ...defaultImage, canDelete }, disabled });

        expect(findDeleteButton().props('disabled')).toBe(isDisabled);
      },
    );
  });

  describe('metadata items', () => {
    describe('tags count', () => {
      it('when there is more than one tag has the correct text', async () => {
        mountComponent();
        await waitForMetadataItems();

        expect(findTagsCount().props('text')).toBe('10 tags');
      });

      it('when there is one tag has the correct text', async () => {
        mountComponent({ image: { ...defaultImage, tagsCount: 1 } });
        await waitForMetadataItems();

        expect(findTagsCount().props('text')).toBe('1 tag');
      });

      it('has the correct icon', async () => {
        mountComponent();
        await waitForMetadataItems();

        expect(findTagsCount().props('icon')).toBe('tag');
      });
    });

    describe('cleanup metadata item', () => {
      it('has the correct icon', async () => {
        mountComponent();
        await waitForMetadataItems();

        expect(findCleanup().props('icon')).toBe('expire');
      });

      it('when the expiration policy is disabled', async () => {
        mountComponent();
        await waitForMetadataItems();

        expect(findCleanup().props()).toMatchObject({
          text: CLEANUP_DISABLED_TEXT,
          textTooltip: CLEANUP_DISABLED_TOOLTIP,
        });
      });

      it.each`
        status                | text                             | tooltip
        ${UNSCHEDULED_STATUS} | ${'Cleanup will run in 1 month'} | ${''}
        ${SCHEDULED_STATUS}   | ${'Cleanup pending'}             | ${CLEANUP_SCHEDULED_TOOLTIP}
        ${ONGOING_STATUS}     | ${'Cleanup in progress'}         | ${CLEANUP_ONGOING_TOOLTIP}
        ${UNFINISHED_STATUS}  | ${'Cleanup incomplete'}          | ${CLEANUP_UNFINISHED_TOOLTIP}
      `(
        'when the status is $status the text is $text and the tooltip is $tooltip',
        async ({ status, text, tooltip }) => {
          mountComponent({
            image: {
              ...defaultImage,
              expirationPolicyCleanupStatus: status,
              project: {
                containerExpirationPolicy: { enabled: true, nextRunAt: '2021-01-03T14:29:21Z' },
              },
            },
          });
          await waitForMetadataItems();

          expect(findCleanup().props()).toMatchObject({
            text,
            textTooltip: tooltip,
          });
        },
      );
    });

    describe('visibility and updated at ', () => {
      it('has last updated text', async () => {
        mountComponent();
        await waitForMetadataItems();

        expect(findLastUpdatedAndVisibility().props('text')).toBe('Last updated 1 month ago');
      });

      describe('visibility icon', () => {
        it('shows an eye when the project is public', async () => {
          mountComponent();
          await waitForMetadataItems();

          expect(findLastUpdatedAndVisibility().props('icon')).toBe('eye');
        });
        it('shows an eye slashed when the project is not public', async () => {
          mountComponent({ image: { ...defaultImage, project: { visibility: 'private' } } });
          await waitForMetadataItems();

          expect(findLastUpdatedAndVisibility().props('icon')).toBe('eye-slash');
        });
      });
    });
  });
});
