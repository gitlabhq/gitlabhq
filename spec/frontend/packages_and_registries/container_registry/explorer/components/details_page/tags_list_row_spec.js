import {
  GlFormCheckbox,
  GlSprintf,
  GlIcon,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlLink,
} from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import TagsListRow from '~/packages_and_registries/container_registry/explorer/components/details_page/tags_list_row.vue';
import SignatureDetailsModal from '~/packages_and_registries/container_registry/explorer/components/details_page/signature_details_modal.vue';
import {
  REMOVE_TAG_BUTTON_TITLE,
  MISSING_MANIFEST_WARNING_TOOLTIP,
  NOT_AVAILABLE_TEXT,
  NOT_AVAILABLE_SIZE,
  COPY_IMAGE_PATH_TITLE,
} from '~/packages_and_registries/container_registry/explorer/constants';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import DetailsRow from '~/vue_shared/components/registry/details_row.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { tagsMock } from '../../mock_data';
import { ListItem } from '../../stubs';

describe('tags list row', () => {
  let wrapper;
  const tag = tagsMock[0];
  const protection = {
    minimumAccessLevelForPush: 'MAINTAINER',
    minimumAccessLevelForDelete: 'MAINTAINER',
  };
  const tagWithOCIMediaType = tagsMock[2];
  const tagWithListMediaType = tagsMock[3];

  const defaultProps = { tag, isMobile: false, index: 0 };

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findName = () => wrapper.findByTestId('name');
  const findSize = () => wrapper.findByTestId('size');
  const findTime = () => wrapper.findByTestId('time');
  const findShortRevision = () => wrapper.findByTestId('digest');
  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const findDetailsRows = () => wrapper.findAllComponents(DetailsRow);
  const findPublishedDateDetail = () => wrapper.findByTestId('published-date-detail');
  const findManifestDetail = () => wrapper.findByTestId('manifest-detail');
  const findManifestMediaType = () => wrapper.findByTestId('manifest-media-type');
  const findConfigurationDetail = () => wrapper.findByTestId('configuration-detail');
  const findSignaturesDetails = () => wrapper.findAllByTestId('signatures-detail');
  const findWarningIcon = () => wrapper.findComponent(GlIcon);
  const findAdditionalActionsMenu = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDeleteButton = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findSignedBadge = () => wrapper.findByTestId('signed-badge');
  const findIndexBadge = () => wrapper.findByTestId('index-badge');
  const findSignatureDetailsModal = () => wrapper.findComponent(SignatureDetailsModal);
  const getTooltipFor = (component) => getBinding(component.element, 'gl-tooltip');
  const findProtectedBadge = () => wrapper.findByTestId('protected-badge');
  const findProtectedPopover = () => wrapper.findByTestId('protected-popover');

  const mountComponent = (propsData = defaultProps, protectedTagsFeatureFlagState = false) => {
    wrapper = shallowMountExtended(TagsListRow, {
      stubs: {
        GlSprintf,
        ListItem,
        DetailsRow,
        GlDisclosureDropdown,
        GlDisclosureDropdownItem,
      },
      propsData,
      directives: { GlTooltip: createMockDirective('gl-tooltip') },
      provide: {
        glFeatures: {
          containerRegistryProtectedTags: protectedTagsFeatureFlagState,
        },
      },
    });
  };

  describe('checkbox', () => {
    it('exists', () => {
      mountComponent();

      expect(findCheckbox().exists()).toBe(true);
    });

    it("does not exist when the row can't be deleted", () => {
      const customTag = { ...tag, userPermissions: { destroyContainerRepositoryTag: false } };

      mountComponent({ ...defaultProps, tag: customTag });

      expect(findCheckbox().exists()).toBe(false);
    });

    it.each`
      digest   | disabled | isDisabled
      ${'foo'} | ${true}  | ${'true'}
      ${null}  | ${true}  | ${'true'}
      ${null}  | ${false} | ${undefined}
      ${'foo'} | ${false} | ${undefined}
    `(
      'disabled attribute is set to $isDisabled when the digest $digest and disabled is $disabled',
      ({ digest, disabled, isDisabled }) => {
        mountComponent({ tag: { ...tag, digest }, disabled });

        expect(findCheckbox().attributes().disabled).toBe(isDisabled);
      },
    );

    it('is wired to the selected prop', () => {
      mountComponent({ ...defaultProps, selected: true });

      expect(findCheckbox().attributes('checked')).toBe('true');
    });

    it('when changed emit a select event', () => {
      mountComponent();

      findCheckbox().vm.$emit('change');

      expect(wrapper.emitted('select')).toEqual([[]]);
    });
  });

  describe('tag name', () => {
    it('exists', () => {
      mountComponent();

      expect(findName().exists()).toBe(true);
    });

    it('has the correct text', () => {
      mountComponent();

      expect(findName().text()).toBe(tag.name);
    });

    it('has a tooltip', () => {
      mountComponent();

      expect(getTooltipFor(findName()).value).toBe(tag.name);
    });

    it('on mobile has gl-max-w-20 class', () => {
      mountComponent({ ...defaultProps, isMobile: true });

      expect(findName().classes('gl-max-w-20')).toBe(true);
    });
  });

  describe('clipboard button', () => {
    it('exist if tag.location exist', () => {
      mountComponent();

      expect(findClipboardButton().exists()).toBe(true);
    });

    it('is hidden if tag does not have a location', () => {
      mountComponent({ ...defaultProps, tag: { ...tag, location: null } });

      expect(findClipboardButton().exists()).toBe(false);
    });

    it('has the correct props/attributes', () => {
      mountComponent();

      expect(findClipboardButton().attributes()).toMatchObject({
        text: tag.location,
        title: COPY_IMAGE_PATH_TITLE,
      });
    });

    it('is disabled when the component is disabled', () => {
      mountComponent({ ...defaultProps, disabled: true });

      expect(findClipboardButton().attributes('disabled')).toBeDefined();
    });
  });

  describe('protected tag', () => {
    it('hidden if tag.protection does not exists', () => {
      mountComponent(defaultProps, true);

      expect(findProtectedBadge().exists()).toBe(false);
    });

    it('displays if tag.protection exists', () => {
      mountComponent(
        {
          ...defaultProps,
          tag: {
            ...tag,
            protection: {
              ...protection,
            },
          },
        },
        true,
      );

      expect(findProtectedBadge().exists()).toBe(true);
    });

    it('has the correct text for the popover', () => {
      mountComponent(
        {
          ...defaultProps,
          tag: {
            ...tag,
            protection: {
              ...protection,
            },
          },
        },
        true,
      );

      const popoverText = findProtectedPopover().text();

      expect(popoverText).toContain('This tag is protected');
      expect(popoverText).toContain('Minimum role to push:');
      expect(popoverText).toContain('Minimum role to delete:');
      expect(popoverText).toContain('MAINTAINER');
    });
  });

  describe('warning icon', () => {
    it('is normally hidden', () => {
      mountComponent();

      expect(findWarningIcon().exists()).toBe(false);
    });

    it('is shown when the tag is broken', () => {
      mountComponent({ tag: { ...tag, digest: null } });

      expect(findWarningIcon().exists()).toBe(true);
    });

    it('has an appropriate tooltip', () => {
      mountComponent({ tag: { ...tag, digest: null } });

      expect(getTooltipFor(findWarningIcon()).value).toBe(MISSING_MANIFEST_WARNING_TOOLTIP);
    });
  });

  describe('size', () => {
    it('exists', () => {
      mountComponent();

      expect(findSize().exists()).toBe(true);
    });

    it('contains the totalSize and layers', () => {
      mountComponent({ ...defaultProps, tag: { ...tag, totalSize: '1024', layers: 10 } });

      expect(findSize().text()).toMatchInterpolatedText('1.00 KiB · 10 layers');
    });

    it('when totalSize is giantic', () => {
      mountComponent({ ...defaultProps, tag: { ...tag, totalSize: '1099511627776', layers: 2 } });

      expect(findSize().text()).toMatchInterpolatedText('1,024.00 GiB · 2 layers');
    });

    it('when totalSize is missing', () => {
      mountComponent({ ...defaultProps, tag: { ...tag, totalSize: '0', layers: 10 } });

      expect(findSize().text()).toMatchInterpolatedText(`${NOT_AVAILABLE_SIZE} · 10 layers`);
    });

    it('when layers are missing', () => {
      mountComponent({ ...defaultProps, tag: { ...tag, totalSize: '1024' } });

      expect(findSize().text()).toMatchInterpolatedText('1.00 KiB');
    });

    it('when there is 1 layer', () => {
      mountComponent({ ...defaultProps, tag: { ...tag, totalSize: '0', layers: 1 } });

      expect(findSize().text()).toMatchInterpolatedText(`${NOT_AVAILABLE_SIZE} · 1 layer`);
    });
  });

  describe('time', () => {
    it('exists', () => {
      mountComponent();

      expect(findTime().exists()).toBe(true);
    });

    it('has the correct text', () => {
      mountComponent();

      expect(findTime().text()).toBe('Published');
    });

    it('contains time_ago_tooltip component', () => {
      mountComponent();

      expect(findTimeAgoTooltip().exists()).toBe(true);
    });

    it('passes publishedAt value to time ago tooltip', () => {
      mountComponent();

      expect(findTimeAgoTooltip().attributes()).toMatchObject({ time: tag.publishedAt });
    });

    describe('when publishedAt is missing', () => {
      beforeEach(() => {
        mountComponent({ ...defaultProps, tag: { ...tag, publishedAt: null } });
      });

      it('passes createdAt value to time ago tooltip', () => {
        expect(findTimeAgoTooltip().attributes()).toMatchObject({ time: tag.createdAt });
      });
    });
  });

  describe('digest', () => {
    it('exists', () => {
      mountComponent();

      expect(findShortRevision().exists()).toBe(true);
    });

    it('has the correct text', () => {
      mountComponent();

      expect(findShortRevision().text()).toMatchInterpolatedText('Digest: 2cf3d2f');
    });

    it(`displays ${NOT_AVAILABLE_TEXT} when digest is missing`, () => {
      mountComponent({ tag: { ...tag, digest: null } });

      expect(findShortRevision().text()).toMatchInterpolatedText(`Digest: ${NOT_AVAILABLE_TEXT}`);
    });
  });

  describe('additional actions menu', () => {
    it('exists', () => {
      mountComponent();

      expect(findAdditionalActionsMenu().exists()).toBe(true);
    });

    it('has the correct props', () => {
      mountComponent();

      expect(findAdditionalActionsMenu().props()).toMatchObject({
        icon: 'ellipsis_v',
        toggleText: 'More actions',
        textSrOnly: true,
        category: 'tertiary',
        placement: 'bottom-end',
        disabled: false,
      });
    });

    it('has the correct classes', () => {
      mountComponent();

      expect(findAdditionalActionsMenu().classes('gl-opacity-0')).toBe(false);
      expect(findAdditionalActionsMenu().classes('gl-pointer-events-none')).toBe(false);
    });

    it('is not rendered when tag.userPermissions.destroyContainerRegistryTag is false', () => {
      mountComponent({
        ...defaultProps,
        tag: { ...tag, userPermissions: { destroyContainerRepositoryTag: false } },
      });

      expect(findAdditionalActionsMenu().exists()).toBe(false);
    });

    it('is hidden when disabled prop is set to true', () => {
      mountComponent({ ...defaultProps, disabled: true });

      expect(findAdditionalActionsMenu().props('disabled')).toBe(true);
      expect(findAdditionalActionsMenu().classes('gl-opacity-0')).toBe(true);
      expect(findAdditionalActionsMenu().classes('gl-pointer-events-none')).toBe(true);
    });

    describe('delete button', () => {
      it('exists and has the correct attrs', () => {
        mountComponent();

        expect(findDeleteButton().exists()).toBe(true);
        expect(findDeleteButton().props('item').extraAttrs).toMatchObject({
          class: '!gl-text-red-500',
          'data-testid': 'single-delete-button',
        });

        expect(findDeleteButton().text()).toBe(REMOVE_TAG_BUTTON_TITLE);
      });

      it('delete event emits delete', () => {
        mountComponent();

        wrapper.findByTestId('single-delete-button').trigger('click');

        expect(wrapper.emitted('delete')).toEqual([[]]);
      });
    });
  });

  describe('details rows', () => {
    describe('when the tag has a digest', () => {
      it('has 3 details rows', async () => {
        mountComponent();
        await nextTick();

        expect(findDetailsRows().length).toBe(3);
      });

      it('has 2 details rows when revision is empty', async () => {
        mountComponent({ tag: { ...tag, revision: '' } });
        await nextTick();

        expect(findDetailsRows().length).toBe(2);
      });

      describe.each`
        name                       | finderFunction             | text                                                                                                            | icon            | clipboard
        ${'published date detail'} | ${findPublishedDateDetail} | ${'Published to the gitlab-org/gitlab-test/rails-12009 image repository on November 5, 2020 at 1:29:38 PM GMT'} | ${'clock'}      | ${false}
        ${'manifest detail'}       | ${findManifestDetail}      | ${'Manifest digest: sha256:2cf3d2fdac1b04a14301d47d51cb88dcd26714c74f91440eeee99ce399089062'}                   | ${'log'}        | ${true}
        ${'manifest media type'}   | ${findManifestMediaType}   | ${'Manifest media type: application/vnd.docker.distribution.manifest.list.v2+json'}                             | ${'media'}      | ${false}
        ${'configuration detail'}  | ${findConfigurationDetail} | ${'Configuration digest: sha256:c2613843ab33aabf847965442b13a8b55a56ae28837ce182627c0716eb08c02b'}              | ${'cloud-gear'} | ${true}
      `('$name details row', ({ finderFunction, text, icon, clipboard }) => {
        const props = { ...defaultProps, tag: tagWithListMediaType };
        it(`has ${text} as text`, async () => {
          mountComponent(props);
          await nextTick();

          expect(finderFunction().text()).toMatchInterpolatedText(text);
        });

        it(`has the ${icon} icon`, async () => {
          mountComponent(props);
          await nextTick();

          expect(finderFunction().props('icon')).toBe(icon);
        });

        if (clipboard) {
          it(`clipboard button exist`, async () => {
            mountComponent(props);
            await nextTick();

            expect(finderFunction().findComponent(ClipboardButton).exists()).toBe(clipboard);
          });

          it('is disabled when the component is disabled', async () => {
            mountComponent({ ...props, disabled: true });
            await nextTick();

            expect(finderFunction().findComponent(ClipboardButton).attributes().disabled).toBe(
              'true',
            );
          });
        }
      });

      describe('when publishedAt is missing', () => {
        beforeEach(() => {
          mountComponent({ ...defaultProps, tag: { ...tag, publishedAt: null } });
        });

        it('name details row has correct text', () => {
          expect(findPublishedDateDetail().text()).toMatchInterpolatedText(
            'Published to the gitlab-org/gitlab-test/rails-12009 image repository on November 3, 2020 at 1:29:38 PM GMT',
          );
        });
      });
    });

    describe('when the tag does not have a digest', () => {
      it('hides the details rows', async () => {
        mountComponent({ tag: { ...tag, digest: null } });

        await nextTick();
        expect(findDetailsRows().length).toBe(0);
      });
    });
  });

  describe('tag signatures', () => {
    describe('without signatures', () => {
      beforeEach(() => {
        mountComponent();
      });

      it('does not show the signed badge', () => {
        expect(findSignedBadge().exists()).toBe(false);
      });

      it('does not show the signature details row', () => {
        expect(findSignaturesDetails().exists()).toBe(false);
      });

      it('does not show the signatures modal', () => {
        expect(findSignatureDetailsModal().exists()).toBe(false);
      });
    });

    describe('with signatures', () => {
      beforeEach(() => {
        mountComponent({
          tag: {
            ...tag,
            referrers: [
              {
                artifactType: 'application/vnd.dev.cosign.artifact.sig.v1+json',
                digest: 'sha256:0',
              },
              {
                artifactType: 'application/vnd.dev.cosign.artifact.sig.v1+json',
                digest: 'sha256:1',
              },
              {
                artifactType: 'not/a/signature',
                digest: 'sha256:deadbeef',
              },
            ],
          },
        });
      });

      it('shows the signed badge with the expected settings', () => {
        expect(findSignedBadge().text()).toBe('Signed');
        expect(findSignedBadge().props('variant')).toBe('muted');
      });

      it('shows the signed badge tooltip', () => {
        expect(getTooltipFor(findSignedBadge()).modifiers.d0).toBe(true);
        expect(getTooltipFor(findSignedBadge()).value).toBe(
          'GitLab is unable to validate this signature automatically. Validate the signature manually before trusting it.',
        );
      });

      describe('signature details rows', () => {
        it('shows the correct number of rows', () => {
          expect(findSignaturesDetails()).toHaveLength(2);
        });

        describe.each([0, 1])('details row %s', (index) => {
          it('shows the pencil icon', () => {
            expect(findSignaturesDetails().at(index).props('icon')).toBe('pencil');
          });

          it('shows the expected text', () => {
            expect(findSignaturesDetails().at(index).text()).toContain(
              `Signature digest: sha256:${index}`,
            );
          });

          it('shows the view details link', () => {
            expect(findSignaturesDetails().at(index).findComponent(GlLink).text()).toBe(
              'View details',
            );
          });
        });
      });

      describe('signature details modal', () => {
        it('does not show modal by default', () => {
          expect(findSignatureDetailsModal().props('visible')).toBe(false);
          expect(findSignatureDetailsModal().props('digest')).toBe(null);
        });

        describe(`when a row's view details link is clicked`, () => {
          beforeEach(() => {
            findSignaturesDetails().at(0).findComponent(GlLink).vm.$emit('click');
          });

          it('shows modal', () => {
            expect(findSignatureDetailsModal().props('visible')).toBe(true);
            expect(findSignatureDetailsModal().props('digest')).toBe('sha256:0');
          });

          it('hides modal when the modal is closed', async () => {
            findSignatureDetailsModal().vm.$emit('close');
            await nextTick();

            expect(findSignatureDetailsModal().props('visible')).toBe(false);
            expect(findSignatureDetailsModal().props('digest')).toBe(null);
          });
        });
      });
    });
  });

  describe('media type', () => {
    it.each`
      description                               | image                   | expectedIndexBadge | expectedSize
      ${'without media type'}                   | ${tag}                  | ${false}           | ${true}
      ${'with OCI index media type'}            | ${tagWithOCIMediaType}  | ${true}            | ${false}
      ${'with Docker manifest list media type'} | ${tagWithListMediaType} | ${true}            | ${false}
    `('$description', ({ image, expectedIndexBadge, expectedSize }) => {
      mountComponent({ ...defaultProps, tag: image });

      expect(findIndexBadge().exists()).toBe(expectedIndexBadge);
      if (expectedIndexBadge) {
        expect(findIndexBadge().text()).toBe('index');
      }
      expect(findSize().exists()).toBe(expectedSize);
    });
  });
});
