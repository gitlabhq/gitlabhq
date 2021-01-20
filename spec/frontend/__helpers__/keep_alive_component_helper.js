import Vue from 'vue';

export function keepAlive(KeptAliveComponent) {
  return Vue.extend({
    components: {
      KeptAliveComponent,
    },
    data() {
      return {
        view: 'KeptAliveComponent',
      };
    },
    methods: {
      async activate() {
        this.view = 'KeptAliveComponent';
        await this.$nextTick();
      },
      async deactivate() {
        this.view = 'div';
        await this.$nextTick();
      },
      async reactivate() {
        await this.deactivate();
        await this.activate();
      },
    },
    template: `<keep-alive><component :is="view"></component></keep-alive>`,
  });
}
