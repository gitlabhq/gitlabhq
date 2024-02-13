import { shallowMount } from '@vue/test-utils';
import glAbilitiesMixin from '~/vue_shared/mixins/gl_abilities_mixin';

describe('GitLab Abilities Mixin', () => {
  let wrapper;

  beforeEach(() => {
    const gon = {
      abilities: {
        aAbility: true,
        bAbility: false,
      },
    };

    const component = {
      template: `<span></span>`,
      mixins: [glAbilitiesMixin()],
    };

    wrapper = shallowMount(component, {
      provide: {
        glAbilities: { ...gon.abilities },
      },
    });
  });

  it('should provide glAbilities to components', () => {
    expect(wrapper.vm.glAbilities).toEqual({
      aAbility: true,
      bAbility: false,
    });
  });
});
