/* eslint-disable max-classes-per-file */

// Helpers
export const spyOnApi = (extension, spiesObj = {}) => {
  const origApi = extension.api;
  if (extension?.obj) {
    jest.spyOn(extension.obj, 'provides').mockReturnValue({
      ...origApi,
      ...spiesObj,
    });
  }
};

// Dummy Extensions
export class SEClassExtension {
  static get extensionName() {
    return 'SEClassExtension';
  }

  // eslint-disable-next-line class-methods-use-this
  provides() {
    return {
      shared: () => 'extension',
      classExtMethod: () => 'class own method',
    };
  }
}

export function SEFnExtension() {
  return {
    extensionName: 'SEFnExtension',
    fnExtMethod: () => 'fn own method',
    provides: () => {
      return {
        fnExtMethod: () => 'class own method',
      };
    },
  };
}

export const SEConstExt = () => {
  return {
    extensionName: 'SEConstExt',
    provides: () => {
      return {
        constExtMethod: () => 'const own method',
      };
    },
  };
};

export const SEExtWithoutAPI = () => {
  return {
    extensionName: 'SEExtWithoutAPI',
  };
};

export class SEWithSetupExt {
  static get extensionName() {
    return 'SEWithSetupExt';
  }
  // eslint-disable-next-line class-methods-use-this
  onSetup(instance, setupOptions = {}) {
    if (setupOptions && !Array.isArray(setupOptions)) {
      Object.entries(setupOptions).forEach(([key, value]) => {
        Object.assign(instance, {
          [key]: value,
        });
      });
    }
  }
  provides() {
    return {
      returnInstanceAndProps: (instance, stringProp, objProp = {}) => {
        return [stringProp, objProp, instance];
      },
      returnInstance: (instance) => {
        return instance;
      },
      giveMeContext: () => {
        return this;
      },
    };
  }
}

export const conflictingExtensions = {
  WithInstanceExt: () => {
    return {
      extensionName: 'WithInstanceExt',
      provides: () => {
        return {
          use: () => 'A conflict with instance',
          ownMethod: () => 'Non-conflicting method',
        };
      },
    };
  },
  WithAnotherExt: () => {
    return {
      extensionName: 'WithAnotherExt',
      provides: () => {
        return {
          shared: () => 'A conflict with extension',
          ownMethod: () => 'Non-conflicting method',
        };
      },
    };
  },
};
