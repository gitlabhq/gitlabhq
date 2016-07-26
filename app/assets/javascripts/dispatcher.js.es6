((global) => {
  class Dispatcher {
    constructor() {
      this.registeredModules = [];
      this.executedModules = [];
      document.addEventListener('page:change', this.processModules.bind(this));
      document.addEventListener('page:before-unload', this.processModules.bind(this));
    }

    /**
     * Registers a module to a page query, or an array of page queries.
     * Module page queries are matched against the `body` `date-page` attribute
     * in order to
     * @param {String} pageQuery - A page query, often taken from the body
     *                           `data-page` attribute.
     *                           e.g. `primary:secondary:tertiary`.
     *                           It can also accept wildcards.
     *                           e.g. `primary:*:tertiary`.
     * @param {Function} module - A function to be invoked when a module's
     *                          page query matches the current page identifier.
     * @return {Undefined}
     */
    register(pageQuery, module) {
      if (_.isArray(pageQuery)) {
        for (pageQuery of pageQuery) {
          this.registerModule(pageQuery, module);
        }
      } else {
        this.registerModule(pageQuery, module);
      }
    }

    processModules(e) {
      const shouldDestroy = (e.type === 'page:before-unload');
      for (let i = 0; i < this.registeredModules.length; i++) {
        const module = this.registeredModules[i];
        if (shouldDestroy) {
          this.destroyModule(module);
        } else {
          this.executeModule(module);
        };
      }
      if (shouldDestroy) this.executedModules = [];
    }

    registerModule(pageQuery, module) {
      this.registeredModules.push({
        pageQuery,
        module,
      });
    }

    destroyModule(module) {
      if (!module.destroyableInstance) return;
      if (module.destroyableInstance.destroy) module.destroyableInstance.destroy();
      delete module.destroyableInstance;
      delete global[module.module.name];
    }

    executeModule(module) {
      if (!this.isExecutable(module)) return;
      try {
        module.destroyableInstance = new module.module();
      } catch (e) {
        module.destroyableInstance = module.module();
      }
      global[module.module.name] = module.module;
      this.executedModules.push(module.module.name);
    }

    isExecutable(module) {
      for (let i = 0; i < this.executedModules.length; i++) {
        const executedModuleName = this.executedModules[i];
        if (module.module.name === executedModuleName) {
          return false;
        }
      }
      return this.matchesPageIdentifier(module)
    }

    matchesPageIdentifier(module) {
      const currentPageIdentifier = document.body.attributes['data-page'].value;
      const pageQueryRegexString = module.pageQuery.replace(/\*/g, '.*');
      const pageQueryRegex = new RegExp(pageQueryRegexString, 'gi');
      return pageQueryRegex.test(currentPageIdentifier);
    }
  }

  global.Dispatcher = new Dispatcher();

})(window.gl || (window.gl = {}));
