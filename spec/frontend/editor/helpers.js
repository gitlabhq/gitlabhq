export class SEClassExtension {
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
    provides: () => {
      return {
        constExtMethod: () => 'const own method',
      };
    },
  };
};

export function SEWithSetupExt() {
  return {
    onSetup: (setupOptions = {}, instance) => {
      if (setupOptions && !Array.isArray(setupOptions)) {
        Object.entries(setupOptions).forEach(([key, value]) => {
          Object.assign(instance, {
            [key]: value,
          });
        });
      }
    },
    provides: () => {
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
    },
  };
}

export const conflictingExtensions = {
  WithInstanceExt: () => {
    return {
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
      provides: () => {
        return {
          shared: () => 'A conflict with extension',
          ownMethod: () => 'Non-conflicting method',
        };
      },
    };
  },
};
