import Vue, { nextTick } from 'vue';
import createComponent from 'helpers/vue_mount_component_helper';
import CommitMessageField from '~/ide/components/commit_sidebar/message_field.vue';

describe('IDE commit message field', () => {
  const Component = Vue.extend(CommitMessageField);
  let vm;

  beforeEach(() => {
    setFixtures('<div id="app"></div>');

    vm = createComponent(
      Component,
      {
        text: '',
        placeholder: 'testing',
      },
      '#app',
    );
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('adds is-focused class on focus', async () => {
    vm.$el.querySelector('textarea').focus();

    await nextTick();
    expect(vm.$el.querySelector('.is-focused')).not.toBeNull();
  });

  it('removed is-focused class on blur', async () => {
    vm.$el.querySelector('textarea').focus();

    await nextTick();
    expect(vm.$el.querySelector('.is-focused')).not.toBeNull();

    vm.$el.querySelector('textarea').blur();

    await nextTick();
    expect(vm.$el.querySelector('.is-focused')).toBeNull();
  });

  it('emits input event on input', () => {
    jest.spyOn(vm, '$emit').mockImplementation();

    const textarea = vm.$el.querySelector('textarea');
    textarea.value = 'testing';

    textarea.dispatchEvent(new Event('input'));

    expect(vm.$emit).toHaveBeenCalledWith('input', 'testing');
  });

  describe('highlights', () => {
    describe('subject line', () => {
      it('does not highlight less than 50 characters', async () => {
        vm.text = 'text less than 50 chars';

        await nextTick();
        expect(vm.$el.querySelector('.highlights span').textContent).toContain(
          'text less than 50 chars',
        );

        expect(vm.$el.querySelector('mark').style.display).toBe('none');
      });

      it('highlights characters over 50 length', async () => {
        vm.text =
          'text less than 50 chars that should not highlighted. text more than 50 should be highlighted';

        await nextTick();
        expect(vm.$el.querySelector('.highlights span').textContent).toContain(
          'text less than 50 chars that should not highlighte',
        );

        expect(vm.$el.querySelector('mark').style.display).not.toBe('none');
        expect(vm.$el.querySelector('mark').textContent).toBe(
          'd. text more than 50 should be highlighted',
        );
      });
    });

    describe('body text', () => {
      it('does not highlight body text less tan 72 characters', async () => {
        vm.text = 'subject line\nbody content';

        await nextTick();
        expect(vm.$el.querySelectorAll('.highlights span').length).toBe(2);
        expect(vm.$el.querySelectorAll('mark')[1].style.display).toBe('none');
      });

      it('highlights body text more than 72 characters', async () => {
        vm.text =
          'subject line\nbody content that will be highlighted when it is more than 72 characters in length';

        await nextTick();
        expect(vm.$el.querySelectorAll('.highlights span').length).toBe(2);
        expect(vm.$el.querySelectorAll('mark')[1].style.display).not.toBe('none');
        expect(vm.$el.querySelectorAll('mark')[1].textContent).toBe(' in length');
      });

      it('highlights body text & subject line', async () => {
        vm.text =
          'text less than 50 chars that should not highlighted\nbody content that will be highlighted when it is more than 72 characters in length';

        await nextTick();
        expect(vm.$el.querySelectorAll('.highlights span').length).toBe(2);
        expect(vm.$el.querySelectorAll('mark').length).toBe(2);

        expect(vm.$el.querySelectorAll('mark')[0].textContent).toContain('d');
        expect(vm.$el.querySelectorAll('mark')[1].textContent).toBe(' in length');
      });
    });
  });

  describe('scrolling textarea', () => {
    it('updates transform of highlights', async () => {
      vm.text = 'subject line\n\n\n\n\n\n\n\n\n\n\nbody content';

      await nextTick();
      vm.$el.querySelector('textarea').scrollTo(0, 50);

      vm.handleScroll();

      await nextTick();
      expect(vm.scrollTop).toBe(50);
      expect(vm.$el.querySelector('.highlights').style.transform).toBe('translate3d(0, -50px, 0)');
    });
  });
});
