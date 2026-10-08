import { GlTooltip } from '@gitlab/ui';
import { NodeViewWrapper } from '@tiptap/vue-2';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PlaceholderWrapper from '~/content_editor/components/wrappers/placeholder.vue';

describe('content/components/wrappers/placeholder', () => {
  let wrapper;

  const createWrapper = (attrs, props = {}) => {
    wrapper = shallowMountExtended(PlaceholderWrapper, {
      propsData: { node: { type: { name: 'placeholder' }, attrs }, ...props },
    });
  };

  const findWrapper = () => wrapper.findComponent(NodeViewWrapper);
  const findDisplayedText = () => findWrapper().element.firstChild.textContent;
  const findTooltip = () => wrapper.findComponent(GlTooltip);
  const findAnnouncement = () => wrapper.findByTestId('content-editor-placeholder-announcement');

  describe('when the placeholder has a value', () => {
    describe('when not selected', () => {
      beforeEach(() => {
        createWrapper({ placeholder: '%{project_name}', value: 'gitlab' });
      });

      it('displays the value', () => {
        expect(findDisplayedText()).toBe('gitlab');
      });

      it('has a hidden tooltip with the placeholder syntax', () => {
        expect(findTooltip().text()).toBe('%{project_name}');
        expect(findTooltip().attributes('show')).toBeUndefined();
      });

      it('announces nothing', () => {
        expect(findAnnouncement().attributes('aria-live')).toBe('polite');
        expect(findAnnouncement().text()).toBe('');
      });

      it('does not have the selected class', () => {
        expect(findWrapper().classes()).toContain('content-editor-placeholder');
        expect(findWrapper().classes()).not.toContain('content-editor-placeholder-selected');
      });
    });

    describe('when selected', () => {
      beforeEach(() => {
        createWrapper({ placeholder: '%{project_name}', value: 'gitlab' }, { selected: true });
      });

      it('shows the tooltip', () => {
        expect(findTooltip().attributes('show')).toBe('true');
      });

      it('announces the value and the placeholder syntax', () => {
        expect(findAnnouncement().text()).toBe('gitlab, placeholder %{project_name}');
      });

      it('has the selected class', () => {
        expect(findWrapper().classes()).toContain('content-editor-placeholder-selected');
      });
    });
  });

  describe('when the placeholder has no value', () => {
    describe('when not selected', () => {
      beforeEach(() => {
        createWrapper({ placeholder: '%{foo}', value: null });
      });

      it('displays the placeholder syntax', () => {
        expect(findDisplayedText()).toBe('%{foo}');
      });

      it('has no tooltip', () => {
        expect(findTooltip().exists()).toBe(false);
      });

      it('announces nothing', () => {
        expect(findAnnouncement().text()).toBe('');
      });
    });

    describe('when selected', () => {
      beforeEach(() => {
        createWrapper({ placeholder: '%{foo}', value: null }, { selected: true });
      });

      it('announces the placeholder syntax', () => {
        expect(findAnnouncement().text()).toBe('Placeholder %{foo}');
      });
    });
  });
});
