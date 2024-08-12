import { builders } from 'prosemirror-test-builder';
import { GlLoadingIcon, GlListboxItem, GlCollapsibleListbox } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import eventHubFactory from '~/helpers/event_hub_factory';
import ReferenceBubbleMenu from '~/content_editor/components/bubble_menus/reference_bubble_menu.vue';
import BubbleMenu from '~/content_editor/components/bubble_menus/bubble_menu.vue';
import { stubComponent } from 'helpers/stub_component';
import Reference from '~/content_editor/extensions/reference';
import { createTestEditor, emitEditorEvent } from '../../test_utils';

const mockWorkItem = {
  href: 'https://gitlab.com/gitlab-org/gitlab/-/work_items/12',
  text: '#12',
  expandedText: 'Et fuga quos omnis enim dolores amet impedit. (#12)',
  fullyExpandedText:
    'Et fuga quos omnis enim dolores amet impedit. (#12) • Fernanda Adams • Sprint - Eligendi quas non inventore eum quaerat sit.',
};
const mockIssue = {
  href: 'https://gitlab.com/gitlab-org/gitlab-test/-/issues/24',
  text: '#24',
  expandedText: 'Et fuga quos omnis enim dolores amet impedit. (#24)',
  fullyExpandedText:
    'Et fuga quos omnis enim dolores amet impedit. (#24) • Fernanda Adams • Sprint - Eligendi quas non inventore eum quaerat sit.',
};
const mockMergeRequest = {
  href: 'https://gitlab.com/gitlab-org/gitlab-test/-/merge_requests/2',
  text: '!2',
  expandedText: 'Qui possimus sit harum ut ipsam autem. (!2)',
  fullyExpandedText: 'Qui possimus sit harum ut ipsam autem. (!2) • Margrett Wunsch • v0.0',
};
const mockEpic = {
  href: 'https://gitlab.com/groups/gitlab-org/-/epics/5',
  text: '&5',
  expandedText: 'Temporibus delectus distinctio quas sed non per... (&5)',
};

describe('content_editor/components/bubble_menus/reference_bubble_menu', () => {
  let wrapper;
  let tiptapEditor;
  let contentEditor;
  let eventHub;
  let doc;
  let p;
  let reference;

  // eslint-disable-next-line max-params
  const buildExpectedDoc = (href, originalText, referenceType, text) =>
    doc(p(reference({ className: 'gfm', href, originalText, referenceType, text })));

  const buildEditor = () => {
    tiptapEditor = createTestEditor({ extensions: [Reference] });
    contentEditor = { resolveReference: jest.fn().mockImplementation(() => new Promise(() => {})) };
    eventHub = eventHubFactory();

    ({ doc, paragraph: p, reference } = builders(tiptapEditor.schema));
  };

  const expectedDocs = {
    issue: [
      () =>
        buildExpectedDoc(
          'https://gitlab.com/gitlab-org/gitlab-test/-/issues/24',
          '#24',
          'issue',
          '#24',
        ),
      () =>
        buildExpectedDoc(
          'https://gitlab.com/gitlab-org/gitlab-test/-/issues/24',
          '#24+',
          'issue',
          'Et fuga quos omnis enim dolores amet impedit. (#24)',
        ),
      () =>
        buildExpectedDoc(
          'https://gitlab.com/gitlab-org/gitlab-test/-/issues/24',
          '#24+s',
          'issue',
          'Et fuga quos omnis enim dolores amet impedit. (#24) • Fernanda Adams • Sprint - Eligendi quas non inventore eum quaerat sit.',
        ),
    ],
    work_item: [
      () =>
        buildExpectedDoc(
          'https://gitlab.com/gitlab-org/gitlab/-/work_items/12',
          '#12',
          'work_item',
          '#12',
        ),
      () =>
        buildExpectedDoc(
          'https://gitlab.com/gitlab-org/gitlab/-/work_items/12',
          '#12+',
          'work_item',
          'Et fuga quos omnis enim dolores amet impedit. (#12)',
        ),
      () =>
        buildExpectedDoc(
          'https://gitlab.com/gitlab-org/gitlab/-/work_items/12',
          '#12+s',
          'work_item',
          'Et fuga quos omnis enim dolores amet impedit. (#12) • Fernanda Adams • Sprint - Eligendi quas non inventore eum quaerat sit.',
        ),
    ],
    merge_request: [
      () =>
        buildExpectedDoc(
          'https://gitlab.com/gitlab-org/gitlab-test/-/merge_requests/2',
          '!2',
          'merge_request',
          '!2',
        ),
      () =>
        buildExpectedDoc(
          'https://gitlab.com/gitlab-org/gitlab-test/-/merge_requests/2',
          '!2+',
          'merge_request',
          'Qui possimus sit harum ut ipsam autem. (!2)',
        ),
      () =>
        buildExpectedDoc(
          'https://gitlab.com/gitlab-org/gitlab-test/-/merge_requests/2',
          '!2+s',
          'merge_request',
          'Qui possimus sit harum ut ipsam autem. (!2) • Margrett Wunsch • v0.0',
        ),
    ],
    epic: [
      () => buildExpectedDoc('https://gitlab.com/groups/gitlab-org/-/epics/5', '&5', 'epic', '&5'),
      () =>
        buildExpectedDoc(
          'https://gitlab.com/groups/gitlab-org/-/epics/5',
          '&5+',
          'epic',
          'Temporibus delectus distinctio quas sed non per... (&5)',
        ),
    ],
  };

  const buildWrapper = () => {
    wrapper = mountExtended(ReferenceBubbleMenu, {
      provide: {
        tiptapEditor,
        contentEditor,
        eventHub,
      },
      stubs: {
        BubbleMenu: stubComponent(BubbleMenu),
      },
    });
  };

  const showMenu = () => {
    wrapper.findComponent(BubbleMenu).vm.$emit('show');
    return nextTick();
  };

  const buildWrapperAndDisplayMenu = async () => {
    buildWrapper();

    await showMenu();
    await emitEditorEvent({ event: 'transaction', tiptapEditor });
  };

  beforeEach(() => {
    buildEditor();

    tiptapEditor
      .chain()
      .setContent(
        '<a href="https://gitlab.com/gitlab-org/gitlab/issues/1" class="gfm" data-reference-type="issue" data-original="#1">#1</a>',
      )
      .setNodeSelection(1)
      .run();
  });

  it('shows a loading indicator while the reference is being resolved', async () => {
    await buildWrapperAndDisplayMenu();

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  describe.each`
    referenceType      | mockReference       | supportedDisplayFormats
    ${'work_item'}     | ${mockWorkItem}     | ${['ID', 'Title', 'Summary']}
    ${'issue'}         | ${mockIssue}        | ${['ID', 'Title', 'Summary']}
    ${'merge_request'} | ${mockMergeRequest} | ${['ID', 'Title', 'Summary']}
    ${'epic'}          | ${mockEpic}         | ${['ID', 'Title']}
  `(
    'for reference type $referenceType',
    ({ referenceType, mockReference, supportedDisplayFormats }) => {
      beforeEach(async () => {
        tiptapEditor
          .chain()
          .setContent(
            `<a href="${mockReference.href}" class="gfm" data-reference-type="${referenceType}" data-original="${mockReference.text}">${mockReference.text}</a>`,
          )
          .setNodeSelection(1)
          .run();

        contentEditor.resolveReference.mockImplementation(() => Promise.resolve(mockReference));
        await emitEditorEvent({ event: 'transaction', tiptapEditor });
      });

      it('shows a dropdown with supported display formats', async () => {
        await buildWrapperAndDisplayMenu();

        supportedDisplayFormats.forEach((format) => expect(wrapper.text()).toContain(format));
      });

      describe.each`
        option | displayFormat                 | selectedValue
        ${0}   | ${supportedDisplayFormats[0]} | ${''}
        ${1}   | ${supportedDisplayFormats[1]} | ${'+'}
        ${2}   | ${supportedDisplayFormats[2]} | ${'+s'}
      `('on selecting option $option', ({ option, displayFormat, selectedValue }) => {
        if (!displayFormat) return;

        const findDropdownItem = () => wrapper.findAllComponents(GlListboxItem).at(option);

        beforeEach(async () => {
          await buildWrapperAndDisplayMenu();

          findDropdownItem().trigger('click');
        });

        it('selects the option', () => {
          expect(wrapper.findComponent(GlCollapsibleListbox).props()).toMatchObject({
            selected: selectedValue,
            toggleText: displayFormat,
          });
        });

        it('updates the reference in content editor', () => {
          expect(tiptapEditor.getJSON()).toEqual(expectedDocs[referenceType][option]().toJSON());
        });
      });
    },
  );

  describe('copy URL button', () => {
    it('copies the reference link to clipboard', async () => {
      jest.spyOn(navigator.clipboard, 'writeText');

      await buildWrapperAndDisplayMenu();
      await wrapper.findByTestId('copy-reference-url').trigger('click');

      expect(navigator.clipboard.writeText).toHaveBeenCalledWith(
        'https://gitlab.com/gitlab-org/gitlab/issues/1',
      );
    });
  });

  describe('remove reference button', () => {
    it('removes the reference', async () => {
      await buildWrapperAndDisplayMenu();
      await wrapper.findByTestId('remove-reference').trigger('click');

      expect(tiptapEditor.getHTML()).toBe('<p dir="auto"></p>');
    });
  });
});
