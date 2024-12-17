import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import CommitMessageField from '~/ide/components/commit_sidebar/message_field.vue';
import { describeSkipVue3, SkipReason } from 'helpers/vue3_conditional';

const skipReason = new SkipReason({
  name: 'IDE commit message field',
  reason: 'Legacy WebIDE is due for deletion',
  issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/508949',
});
describeSkipVue3(skipReason, () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(CommitMessageField, {
      propsData: {
        text: '',
        placeholder: 'testing',
      },
      attachTo: document.body,
    });
  });

  const findMessage = () => wrapper.find('textarea');
  const findHighlights = () => wrapper.findAll('.highlights span');
  const findMarks = () => wrapper.findAll('mark');

  it('adds is-focused class on focus', async () => {
    await findMessage().trigger('focus');

    expect(wrapper.find('.is-focused').exists()).toBe(true);
  });

  it('removed is-focused class on blur', async () => {
    await findMessage().trigger('focus');

    expect(wrapper.find('.is-focused').exists()).toBe(true);

    await findMessage().trigger('blur');

    expect(wrapper.find('.is-focused').exists()).toBe(false);
  });

  it('emits input event on input', async () => {
    await findMessage().setValue('testing');

    expect(wrapper.emitted('input')[0]).toStrictEqual(['testing']);
  });

  describe('highlights', () => {
    describe('subject line', () => {
      it('does not highlight less than 50 characters', async () => {
        await wrapper.setProps({ text: 'text less than 50 chars' });

        expect(findHighlights()).toHaveLength(1);
        expect(findHighlights().at(0).text()).toContain('text less than 50 chars');

        expect(findMarks()).toHaveLength(1);
        expect(findMarks().at(0).isVisible()).toBe(false);
      });

      it('highlights characters over 50 length', async () => {
        await wrapper.setProps({
          text: 'text less than 50 chars that should not highlighted. text more than 50 should be highlighted',
        });

        expect(findHighlights()).toHaveLength(1);
        expect(findHighlights().at(0).text()).toContain(
          'text less than 50 chars that should not highlighte',
        );

        expect(findMarks()).toHaveLength(1);
        expect(findMarks().at(0).isVisible()).toBe(true);
        expect(findMarks().at(0).text()).toBe('d. text more than 50 should be highlighted');
      });
    });

    describe('body text', () => {
      it('does not highlight body text less tan 72 characters', async () => {
        await wrapper.setProps({ text: 'subject line\nbody content' });

        expect(findHighlights()).toHaveLength(2);
        expect(findMarks().at(1).isVisible()).toBe(false);
      });

      it('highlights body text more than 72 characters', async () => {
        await wrapper.setProps({
          text: 'subject line\nbody content that will be highlighted when it is more than 72 characters in length',
        });

        expect(findHighlights()).toHaveLength(2);
        expect(findMarks().at(1).isVisible()).toBe(true);
        expect(findMarks().at(1).text()).toBe('in length');
      });

      it('highlights body text & subject line', async () => {
        await wrapper.setProps({
          text: 'text less than 50 chars that should not highlighted\nbody content that will be highlighted when it is more than 72 characters in length',
        });

        expect(findHighlights()).toHaveLength(2);
        expect(findMarks()).toHaveLength(2);

        expect(findMarks().at(0).text()).toContain('d');
        expect(findMarks().at(1).text()).toBe('in length');
      });
    });
  });

  describe('scrolling textarea', () => {
    it('updates transform of highlights', async () => {
      await wrapper.setProps({ text: 'subject line\n\n\n\n\n\n\n\n\n\n\nbody content' });

      findMessage().element.scrollTo(0, 50);
      await nextTick();

      expect(wrapper.find('.highlights').element.style.transform).toBe('translate3d(0, -50px, 0)');
    });
  });
});
