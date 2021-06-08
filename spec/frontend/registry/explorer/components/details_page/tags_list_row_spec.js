import { GlFormCheckbox, GlSprintf, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';

import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import DeleteButton from '~/registry/explorer/components/delete_button.vue';
import component from '~/registry/explorer/components/details_page/tags_list_row.vue';
import {
  REMOVE_TAG_BUTTON_TITLE,
  REMOVE_TAG_BUTTON_DISABLE_TOOLTIP,
  MISSING_MANIFEST_WARNING_TOOLTIP,
  NOT_AVAILABLE_TEXT,
  NOT_AVAILABLE_SIZE,
} from '~/registry/explorer/constants/index';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import DetailsRow from '~/vue_shared/components/registry/details_row.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import { tagsMock } from '../../mock_data';
import { ListItem } from '../../stubs';

describe('tags list row', () => {
  let wrapper;
  const [tag] = [...tagsMock];

  const defaultProps = { tag, isMobile: false, index: 0 };

  const findCheckbox = () => wrapper.find(GlFormCheckbox);
  const findName = () => wrapper.find('[data-testid="name"]');
  const findSize = () => wrapper.find('[data-testid="size"]');
  const findTime = () => wrapper.find('[data-testid="time"]');
  const findShortRevision = () => wrapper.find('[data-testid="digest"]');
  const findClipboardButton = () => wrapper.find(ClipboardButton);
  const findDeleteButton = () => wrapper.find(DeleteButton);
  const findTimeAgoTooltip = () => wrapper.find(TimeAgoTooltip);
  const findDetailsRows = () => wrapper.findAll(DetailsRow);
  const findPublishedDateDetail = () => wrapper.find('[data-testid="published-date-detail"]');
  const findManifestDetail = () => wrapper.find('[data-testid="manifest-detail"]');
  const findConfigurationDetail = () => wrapper.find('[data-testid="configuration-detail"]');
  const findWarningIcon = () => wrapper.find(GlIcon);

  const mountComponent = (propsData = defaultProps) => {
    wrapper = shallowMount(component, {
      stubs: {
        GlSprintf,
        ListItem,
        DetailsRow,
      },
      propsData,
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('checkbox', () => {
    it('exists', () => {
      mountComponent();

      expect(findCheckbox().exists()).toBe(true);
    });

    it("does not exist when the row can't be deleted", () => {
      const customTag = { ...tag, canDelete: false };

      mountComponent({ ...defaultProps, tag: customTag });

      expect(findCheckbox().exists()).toBe(false);
    });

    it.each`
      digest   | disabled
      ${'foo'} | ${true}
      ${null}  | ${false}
      ${null}  | ${true}
      ${'foo'} | ${true}
    `('is disabled when the digest $digest and disabled is $disabled', ({ digest, disabled }) => {
      mountComponent({ tag: { ...tag, digest }, disabled });

      expect(findCheckbox().attributes('disabled')).toBe('true');
    });

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

      const tooltip = getBinding(findName().element, 'gl-tooltip');

      expect(tooltip.value.title).toBe(tag.name);
    });

    it('on mobile has mw-s class', () => {
      mountComponent({ ...defaultProps, isMobile: true });

      expect(findName().classes('mw-s')).toBe(true);
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
        title: tag.location,
      });
    });

    it('is disabled when the component is disabled', () => {
      mountComponent({ ...defaultProps, disabled: true });

      expect(findClipboardButton().attributes('disabled')).toBe('true');
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

      const tooltip = getBinding(findWarningIcon().element, 'gl-tooltip');
      expect(tooltip.value.title).toBe(MISSING_MANIFEST_WARNING_TOOLTIP);
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

      expect(findSize().text()).toMatchInterpolatedText('1024.00 GiB · 2 layers');
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

    it('pass the correct props to time ago tooltip', () => {
      mountComponent();

      expect(findTimeAgoTooltip().attributes()).toMatchObject({ time: tag.createdAt });
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

  describe('delete button', () => {
    it('exists', () => {
      mountComponent();

      expect(findDeleteButton().exists()).toBe(true);
    });

    it('has the correct props/attributes', () => {
      mountComponent();

      expect(findDeleteButton().attributes()).toMatchObject({
        title: REMOVE_TAG_BUTTON_TITLE,
        tooltiptitle: REMOVE_TAG_BUTTON_DISABLE_TOOLTIP,
        tooltipdisabled: 'true',
      });
    });

    it.each`
      canDelete | digest   | disabled
      ${true}   | ${null}  | ${true}
      ${false}  | ${'foo'} | ${true}
      ${false}  | ${null}  | ${true}
      ${true}   | ${'foo'} | ${true}
    `(
      'is disabled when canDelete is $canDelete and digest is $digest and disabled is $disabled',
      ({ canDelete, digest, disabled }) => {
        mountComponent({ ...defaultProps, tag: { ...tag, canDelete, digest }, disabled });

        expect(findDeleteButton().attributes('disabled')).toBe('true');
      },
    );

    it('delete event emits delete', () => {
      mountComponent();

      findDeleteButton().vm.$emit('delete');

      expect(wrapper.emitted('delete')).toEqual([[]]);
    });
  });

  describe('details rows', () => {
    describe('when the tag has a digest', () => {
      it('has 3 details rows', async () => {
        mountComponent();
        await nextTick();

        expect(findDetailsRows().length).toBe(3);
      });

      describe.each`
        name                       | finderFunction             | text                                                                                                 | icon            | clipboard
        ${'published date detail'} | ${findPublishedDateDetail} | ${'Published to the gitlab-org/gitlab-test/rails-12009 image repository at 01:29 UTC on 2020-11-03'} | ${'clock'}      | ${false}
        ${'manifest detail'}       | ${findManifestDetail}      | ${'Manifest digest: sha256:2cf3d2fdac1b04a14301d47d51cb88dcd26714c74f91440eeee99ce399089062'}        | ${'log'}        | ${true}
        ${'configuration detail'}  | ${findConfigurationDetail} | ${'Configuration digest: sha256:c2613843ab33aabf847965442b13a8b55a56ae28837ce182627c0716eb08c02b'}   | ${'cloud-gear'} | ${true}
      `('$name details row', ({ finderFunction, text, icon, clipboard }) => {
        it(`has ${text} as text`, async () => {
          mountComponent();
          await nextTick();

          expect(finderFunction().text()).toMatchInterpolatedText(text);
        });

        it(`has the ${icon} icon`, async () => {
          mountComponent();
          await nextTick();

          expect(finderFunction().props('icon')).toBe(icon);
        });

        if (clipboard) {
          it(`clipboard button exist`, async () => {
            mountComponent();
            await nextTick();

            expect(finderFunction().find(ClipboardButton).exists()).toBe(clipboard);
          });

          it('is disabled when the component is disabled', async () => {
            mountComponent({ ...defaultProps, disabled: true });
            await nextTick();

            expect(finderFunction().findComponent(ClipboardButton).attributes('disabled')).toBe(
              'true',
            );
          });
        }
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
});
