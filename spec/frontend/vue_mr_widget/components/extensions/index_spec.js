import { registerExtension, extensions } from '~/vue_merge_request_widget/components/extensions';
import ExtensionBase from '~/vue_merge_request_widget/components/extensions/base.vue';

describe('MR widget extension registering', () => {
  it('registers a extension', () => {
    registerExtension({
      name: 'Test',
      props: ['helloWorld'],
      computed: {
        test() {},
      },
      methods: {
        test() {},
      },
    });

    expect(extensions[0]).toEqual(
      expect.objectContaining({
        extends: ExtensionBase,
        name: 'Test',
        props: ['helloWorld'],
        computed: {
          test: expect.any(Function),
        },
        methods: {
          test: expect.any(Function),
        },
      }),
    );
  });
});
