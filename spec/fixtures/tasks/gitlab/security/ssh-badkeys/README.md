# SSH Bad Keys

This is a collection of static SSH keys (host and authentication) that have made their way into software and hardware products. This was inspired by the [Little Black Box](https://code.google.com/p/littleblackbox/) project, but focused primarily on SSH (as opposed to TLS) keys.

Keys are split into two categories; authorized keys and host keys. The authorized keys can be used to gain access to a device with this public key. The host keys can be used to conduct a MITM attack against the device, but do not provide direct access.

This collection depends on submissions from researchers to stay relevant. If you are aware of a static key (host or authorized), please open an [Issue](https://github.com/rapid7/ssh-badkeys/issues) or submit a Pull Request. The [Issues](https://github.com/rapid7/ssh-badkeys/issues) list also contains a wishlist of known bad keys that we would like to include.

For additional key types and a broader scope, take a look at the [Kompromat](https://github.com/BenBE/kompromat) project.



