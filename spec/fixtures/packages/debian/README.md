# Build a Debian package

Install the build dependencies:

```shell
sudo apt install dpkg-dev
```

Go to the `spec/fixtures/packages/debian` directory and clean up old files:

```shell
cd spec/fixtures/packages/debian
rm -v *.tar.* *.dsc *.deb *.udeb *.ddeb *.buildinfo *.changes
```

Go to the package source directory and build:

```shell
cd sample
dpkg-buildpackage --no-sign
```
