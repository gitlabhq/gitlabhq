import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import GlAbilities from '~/vue_shared/gl_abilities_plugin';

describe('GitLab Abilities Plugin', () => {
  beforeEach(() => {
    window.gon = {
      abilities: {
        aAbility: true,
        bAbility: false,
      },
    };

    Vue.use(GlAbilities);
  });

  it('should provide glAbilities to components', () => {
    const component = {
      template: `<span></span>`,
      inject: ['glAbilities'],
    };
    const wrapper = shallowMount(component);
    expect(wrapper.vm.glAbilities).toEqual({
      aAbility: true,
      bAbility: false,
    });
  });
});
